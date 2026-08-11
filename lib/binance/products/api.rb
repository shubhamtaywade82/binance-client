# frozen_string_literal: true

require 'logger'

module Binance
  module Products
    # Generic API client for any Binance product (spot, wallet, margin, ...).
    # All 888 REST endpoints across 36 products are reachable via the catalog:
    #   api.request(:get_api_v3_klines, symbol: 'BTCUSDT', interval: '1h')
    #   api.get_api_v3_klines(symbol: 'BTCUSDT', interval: '1h')
    class API
      # Error handling for HTTP responses and transport failures.
      module ResponseHandling
        private

        def execute_on_transport(endpoint, request_obj)
          response = transport_for(endpoint[:host]).execute(request_obj, timestamp_provider: clock)
          handle_response_body(response.body, response.status, endpoint)
          response.body
        rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
          raise_transport_error(e)
        end

        def raise_transport_error(error)
          case error
          when Faraday::TimeoutError
            logger.error("Request timeout: #{error.message}")
            raise TimeoutError, "Request timeout: #{error.message}"
          else
            logger.error("Connection failed: #{error.message}")
            raise ConnectionError, "Failed to connect to Binance API: #{error.message}"
          end
        end

        def handle_response_body(body, status, endpoint)
          return unless body.is_a?(Hash) && body['code']

          code = body['code'].to_i
          return if ok_response?(code, status)

          raise Binance.create_error(
            code: code,
            message: body['msg'] || 'Unknown error',
            http_status: status,
            endpoint: endpoint[:path]
          )
        end

        def ok_response?(code, status)
          code == 200 || (status && (200..299).cover?(status) && code.positive?)
        end
      end

      include ResponseHandling

      attr_reader :product, :api_key, :secret_key, :testnet, :logger, :clock

      # Initialize a product API client
      # @param product [Symbol] Product key from the catalog (e.g. :spot, :wallet)
      # @param api_key [String, nil] Binance API key (optional for public data)
      # @param secret_key [String, nil] Binance API secret (optional for public data)
      # @param testnet [Boolean] Use testnet host (default: false)
      # @param logger [Logger] Custom logger (optional)
      # @param timeout [Integer] HTTP timeout in seconds (default: 30)
      def initialize(product:, api_key: nil, secret_key: nil, testnet: false, logger: nil, timeout: 30)
        metadata = Core::Catalog.product_metadata(product)
        raise ArgumentError, "Unknown product: #{product}" unless metadata

        @product = product
        @api_key = api_key
        @secret_key = secret_key
        @testnet = testnet
        @logger = logger || default_logger
        @clock = Core::Clock.new
        @timeout = timeout
        @transports = {}
      end

      # Execute an endpoint from the catalog
      # @param action [Symbol] Action key (e.g. :get_api_v3_klines)
      # @param params [Hash] Request parameters (may also be given as keyword args)
      # @param encoding [Symbol, nil] Override encoding (:query, :form, :json)
      # @return [Hash, Array] Parsed JSON response
      # @raise [ArgumentError] If the action is unknown for this product
      def request(action, params = {}, encoding: nil, **kwargs)
        params = params.merge(kwargs)
        endpoint = Core::Catalog.find(product, action)
        raise ArgumentError, "Unknown endpoint: #{product}.#{action}" unless endpoint

        request_obj = build_request(endpoint[:method], endpoint[:path], params, endpoint[:security],
                                    encoding || default_encoding(endpoint))
        sync_time_if_needed!(request_obj)
        execute_on_transport(endpoint.merge(host: resolved_host(endpoint[:host])), request_obj)
      end

      # Execute an endpoint against a raw path (for endpoints not in the catalog)
      # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
      # @param path [String] API path (e.g. '/api/v3/time')
      # @param params [Hash] Request parameters
      # @param signed [Boolean] Whether the request requires a signature
      # @return [Hash, Array] Parsed JSON response
      def execute(method, path, params = {}, signed: true)
        request_obj = build_request(method, path, params, signed ? :trade : :market, default_encoding(method: method))
        sync_time_if_needed!(request_obj)
        execute_on_transport({ host: resolved_host(metadata[:host]), path: path }, request_obj)
      end

      # Convenience wrappers for execute
      def get(path, params = {}, signed: false, **kwargs)
        execute(:get, path, params, signed: signed, **kwargs)
      end

      def post(path, params = {}, signed: true, **kwargs)
        execute(:post, path, params, signed: signed, **kwargs)
      end

      def put(path, params = {}, signed: true, **kwargs)
        execute(:put, path, params, signed: signed, **kwargs)
      end

      def delete(path, params = {}, signed: true, **kwargs)
        execute(:delete, path, params, signed: signed, **kwargs)
      end

      # List all available actions for this product
      # @return [Array<Symbol>] Action keys
      def actions
        Core::Catalog.for_product(product).map { |e| e[:action] }
      end

      # Get product metadata
      # @return [Hash] Product metadata
      def metadata
        Core::Catalog.product_metadata(product)
      end

      # Synchronize clock with the product's time endpoint
      # @return [Integer, nil] Server time in ms (nil if the product has no time endpoint)
      def sync_time!
        time_path = metadata[:time_path]
        return nil unless time_path

        response = execute_on_transport(
          { host: resolved_host(metadata[:host]), path: time_path },
          Core::Transport::Request.new(method: :get, path: time_path, security: :none, encoding: :query)
        )
        clock.sync(response['serverTime'])
        logger.info("Time synchronized for #{product}: offset=#{clock.offset_str}")
        response['serverTime']
      end

      # Check if the client has credentials for signed requests
      # @return [Boolean]
      def authenticated?
        !@api_key.nil? && !@secret_key.nil?
      end

      private

      # Time synchronization before signed requests.
      def sync_time_if_needed!(request_obj)
        return unless request_obj.signed? && clock.sync_needed? && metadata[:time_path]

        sync_time!
      rescue StandardError => e
        logger.warn("Auto time sync failed for #{product}: #{e.message}")
      end

      def build_request(method, path, params, security, encoding)
        Core::Transport::Request.new(
          method: method,
          path: path,
          params: params,
          security: security,
          encoding: encoding
        )
      end

      def default_encoding(endpoint = nil, method: nil)
        return :query if endpoint && endpoint[:security] == :user_stream

        http_method = method || endpoint[:method]
        return :query if %i[get delete].include?(http_method)

        :form
      end

      # Swap a production host for its testnet equivalent when testnet: true.
      # Falls back to production (with a one-time warning) for products/hosts
      # Binance offers no sandbox for, rather than silently trading live.
      def resolved_host(host)
        return host unless @testnet

        testnet_host = metadata[:testnet_host]
        return testnet_host if testnet_host && host == metadata[:host]

        warn_no_testnet(host)
        host
      end

      def warn_no_testnet(host)
        @testnet_warned ||= {}
        return if @testnet_warned[host]

        @testnet_warned[host] = true
        logger.warn("testnet: true requested for #{product}, but #{host} has no known testnet host — using production")
      end

      def transport_for(host)
        @transports[host] ||= Core::Transport::HTTP.new(
          base_url: host,
          api_key: @api_key,
          secret_key: @secret_key,
          timeout: @timeout,
          logger: @logger
        )
      end

      def default_logger
        Logger.new($stdout).tap do |log|
          log.level = ENV.fetch('BINANCE_LOG_LEVEL', 'WARN').to_sym
        end
      end
    end
  end
end
