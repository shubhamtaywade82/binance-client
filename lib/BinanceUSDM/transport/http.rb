# frozen_string_literal: true

require 'faraday'
require 'json'
require_relative 'request'
require_relative 'response'
require_relative '../helpers/signature_helper'

module BinanceUSDM
  module Transport
    # HTTP transport layer for Binance API communication.
    class HTTP
      attr_reader :base_url, :api_key, :secret_key, :timeout, :logger

      def initialize(base_url:, api_key:, secret_key:, timeout: 30, logger: nil)
        @base_url = base_url
        @api_key = api_key
        @secret_key = secret_key
        @timeout = timeout
        @logger = logger || default_logger
        @connection = nil
      end

      # Execute HTTP request
      # @param request [Request]
      # @param timestamp_provider [Object]
      # @return [Response]
      def execute(request, timestamp_provider: nil)
        url, body = prepare_url_and_body(request, timestamp_provider)
        headers = build_headers(request)
        log_request(request, url, headers)

        build_response(connection.run_request(request.method, url, body, headers))
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        raise_transport_error(e)
      end

      def connection
        @connection ||= Faraday.new do |conn|
          conn.adapter :net_http
          conn.options.timeout = timeout
          conn.options.open_timeout = 10
        end
      end

      private

      def raise_transport_error(error)
        if error.is_a?(Faraday::TimeoutError)
          logger.error("Request timeout: #{error.message}")
          raise TimeoutError, "Request timeout: #{error.message}"
        end

        logger.error("Connection failed: #{error.message}")
        raise ConnectionError, "Failed to connect to Binance API: #{error.message}"
      end

      def build_response(response)
        Response.new(
          status: response.status,
          body: parse_body(response.body),
          headers: response.headers.to_h
        )
      end

      def prepare_url_and_body(request, timestamp_provider)
        provider = timestamp_provider || SignatureHelper
        path_url = "#{base_url}#{request.path}"
        request.signed? ? build_signed_payload(request, provider, path_url) : build_unsigned_payload(request, path_url)
      end

      def build_signed_payload(request, provider, path_url)
        params = request.params.dup
        signed_query = SignatureHelper.build_signed_query_for_transport(
          params,
          api_key,
          secret_key,
          timestamp: provider.timestamp,
          recv_window: params.delete(:recv_window) || params.delete(:recvWindow) || 5000
        )
        signed_target(request, path_url, signed_query)
      end

      def signed_target(request, path_url, query)
        if %i[get delete].include?(request.method) || request.encoding == :query
          ["#{path_url}?#{query}", nil]
        else
          [path_url, query]
        end
      end

      def build_unsigned_payload(request, path_url)
        formatted = SignatureHelper.format_params(request.params)
        return [path_url, nil] if formatted.empty?

        if %i[get delete].include?(request.method)
          query = URI.encode_www_form(formatted)
          ["#{path_url}?#{query}", nil]
        else
          body = request.encoding == :json ? JSON.dump(formatted) : URI.encode_www_form(formatted)
          [path_url, body]
        end
      end

      def build_headers(request)
        { 'Content-Type' => content_type(request) }.tap do |headers|
          headers['X-MBX-APIKEY'] = api_key if api_key && (request.needs_api_key? || request.signed?)
        end
      end

      def content_type(request)
        request.encoding == :json ? 'application/json' : 'application/x-www-form-urlencoded'
      end

      def parse_body(body)
        return {} if body.nil? || body.empty?

        JSON.parse(body)
      rescue JSON::ParserError => e
        logger.error("Failed to parse response: #{e.message}")
        raise ApiError.new(message: "Invalid JSON response: #{e.message}", code: -1)
      end

      def log_request(request, _url, _headers)
        return unless logger.debug?

        safe_params = sanitize_params(request.params)
        logger.debug("[REQUEST] #{request.method_str} #{request.path} params=#{safe_params.inspect}")
      end

      def sanitize_params(params)
        params.dup.tap { |p| %i[apiKey signature].each { |k| p[k] = '***REDACTED***' if p.key?(k) } }
      end

      def default_logger
        Logger.new($stdout).tap { |log| log.level = ENV.fetch('BINANCE_LOG_LEVEL', 'WARN').to_sym }
      end
    end
  end
end
