# frozen_string_literal: true

require 'faraday'
require 'json'
require 'logger'
require_relative 'transport/http'
require_relative 'transport/request'
require_relative 'transport/endpoint'
require_relative 'authentication/clock'
require_relative 'rate_limit/manager'

module BinanceUSDM
  # HTTP client for making API requests to Binance.
  class Client
    # Error handling for HTTP responses and transport failures.
    module ResponseHandling
      private

      def perform(request_obj, endpoint)
        response = @http.execute(request_obj, timestamp_provider: clock)
        rate_limiter.update_from_headers(response.headers)
        handle_response_body(response.body, response.status, response.headers, endpoint)
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

      def handle_response_body(body, status, headers, endpoint)
        return unless body.is_a?(Hash) && body['code']

        code = body['code'].to_i
        return if ok_response?(code, status)

        raise build_api_error(code, body, status, headers, endpoint)
      end

      def ok_response?(code, status)
        code == 200 || (status && (200..299).cover?(status) && code.positive?)
      end

      def build_api_error(code, body, status, headers, endpoint)
        message = body['msg'] || 'Unknown error'
        error = BinanceUSDM.create_error(
          code: code,
          message: message,
          http_status: status,
          headers: headers,
          endpoint: endpoint
        )
        logger.error("[API ERROR] #{error.class}: #{message} (code: #{code})")
        error
      end
    end

    # Time synchronization before signed requests.
    module TimeSync
      private

      def sync_time_if_needed!(request_obj)
        return unless auto_sync_time && clock.sync_needed? && request_obj.signed?

        sync_time!
      rescue StandardError => e
        logger.warn("Auto time sync failed: #{e.message}")
      end
    end

    include ResponseHandling
    include TimeSync

    attr_reader :api_key, :secret_key, :testnet, :logger, :clock, :rate_limiter, :http,
                :order, :account, :market, :algo_orders
    attr_accessor :auto_sync_time

    def initialize(api_key:, secret_key:, testnet: false, logger: nil, timeout: 30)
      @api_key = api_key
      @secret_key = secret_key
      @testnet = testnet
      @logger = logger || default_logger
      @base_url = testnet ? Constants::Urls::TESTNET_REST_API_BASE : Constants::Urls::REST_API_BASE
      @clock = Authentication::Clock.new
      @auto_sync_time = true
      @rate_limiter = RateLimit::Manager.new
      @http = build_http(timeout)
      build_resources
    end

    def connection
      @http.connection
    end

    def time_offset
      clock.time_offset
    end

    def server_time
      clock.now
    end

    # Synchronize time with Binance server
    # @raise [NetworkError] if sync fails
    def sync_time!
      server_time_ms = @http.execute(
        Transport::Request.new(method: :get, path: '/fapi/v1/time', security: :market, encoding: :query)
      ).body['serverTime']

      clock.sync(server_time_ms)
      logger.info("Time synchronized with Binance server: offset=#{clock.offset_str}")
      server_time_ms
    rescue StandardError => e
      logger.error("Failed to sync time: #{e.message}")
      raise
    end

    # Perform GET request
    # @return [Hash, Array] Parsed JSON response
    def get(endpoint, params: {}, signed: true, security: nil, encoding: :query)
      request(:get, endpoint, params, signed: signed, security: security, encoding: encoding)
    end

    # Perform POST request
    # @return [Hash, Array] Parsed JSON response
    def post(endpoint, params: {}, signed: true, security: nil, encoding: :form)
      request(:post, endpoint, params, signed: signed, security: security, encoding: encoding)
    end

    # Perform PUT request
    # @return [Hash, Array] Parsed JSON response
    def put(endpoint, params: {}, signed: true, security: nil, encoding: :form)
      request(:put, endpoint, params, signed: signed, security: security, encoding: encoding)
    end

    # Perform DELETE request
    # @return [Hash, Array] Parsed JSON response
    def delete(endpoint, params: {}, signed: true, security: nil, encoding: :query)
      request(:delete, endpoint, params, signed: signed, security: security, encoding: encoding)
    end

    # Execute request with endpoint spec
    # @param endpoint_spec [Transport::EndpointSpec] Endpoint specification
    # @param params [Hash] Request parameters
    # @return [Hash, Array] Parsed JSON response
    def execute(endpoint_spec, params = {})
      request_obj = endpoint_spec.build_request(params)
      sync_time_if_needed!(request_obj)
      enforce_rate_limit!(endpoint_spec)
      perform(request_obj, endpoint_spec.path)
    end

    private

    # Perform HTTP request with error handling
    # @return [Hash, Array] Parsed JSON response
    def request(method, endpoint, params, **options)
      request_obj = Transport::Request.new(
        method: method,
        path: endpoint,
        params: params,
        security: options[:security] || (options[:signed] ? :trade : :market),
        encoding: options[:encoding] || :query
      )
      sync_time_if_needed!(request_obj)
      perform(request_obj, endpoint)
    end

    # Raise when the rate limiter rejects the request
    def enforce_rate_limit!(endpoint_spec)
      return if rate_limiter.allow?(endpoint_spec)

      logger.warn("Rate limit exceeded for #{endpoint_spec.path}")
      raise RateLimitError, 'Rate limit exceeded'
    end

    # Default logger
    # @return [Logger]
    def default_logger
      Logger.new($stdout).tap do |log|
        log.level = ENV.fetch('BINANCE_LOG_LEVEL', 'WARN').to_sym
      end
    end

    def build_http(timeout)
      Transport::HTTP.new(
        base_url: @base_url,
        api_key: @api_key,
        secret_key: @secret_key,
        timeout: timeout,
        logger: @logger
      )
    end

    def build_resources
      @order = Resources::Order.new(self)
      @account = Resources::Account.new(self)
      @market = Resources::Market.new(self)
      @algo_orders = Resources::AlgoOrder.new(self)
    end
  end
end
