# frozen_string_literal: true

require "faraday"
require "json"
require_relative "request"
require_relative "response"
require_relative "../helpers/signature_helper"

module BinanceUSDM
  module Transport
    # HTTP transport layer for Binance API communication.
    class HTTP
      attr_reader :base_url, :api_key, :secret_key, :timeout, :logger

      # Initialize HTTP transport
      # @param base_url [String] Base API URL
      # @param api_key [String] API key
      # @param secret_key [String] API secret
      # @param timeout [Integer] Request timeout in seconds
      # @param logger [Logger] Logger instance
      def initialize(base_url:, api_key:, secret_key:, timeout: 30, logger: nil)
        @base_url = base_url
        @api_key = api_key
        @secret_key = secret_key
        @timeout = timeout
        @logger = logger || default_logger
        @connection = nil
      end

      # Execute a request
      # @param request [Request] Request object
      # @param timestamp_provider [Object] Object providing timestamp method
      # @return [Response] Response object
      def execute(request, timestamp_provider: nil)
        url = build_url(request, timestamp_provider: timestamp_provider)
        headers = build_headers(request)
        body = build_body(request)

        log_request(request, url, headers)

        response = connection.send(request.method, url, body, headers)
        
        Response.new(
          status: response.status,
          body: parse_body(response.body),
          headers: response.headers.to_h
        )
      rescue Faraday::ConnectionFailed => e
        logger.error("Connection failed: #{e.message}")
        raise Errors::ConnectionError, "Failed to connect to Binance API: #{e.message}"
      rescue Faraday::TimeoutError => e
        logger.error("Request timeout: #{e.message}")
        raise Errors::TimeoutError, "Request timeout: #{e.message}"
      end

      private

      # Build Faraday connection
      # @return [Faraday::Connection]
      def connection
        @connection ||= Faraday.new do |conn|
          conn.adapter :net_http
          conn.options.timeout = timeout
          conn.options.open_timeout = 10
        end
      end

      # Build full URL with query string
      # @param request [Request] Request object
      # @param timestamp_provider [Object] Timestamp provider
      # @return [String] Full URL
      def build_url(request, timestamp_provider: nil)
        query_params = {}
        body_params = request.params.dup

        if request.signed?
          timestamp_provider ||= SignatureHelper
          query_params[:timestamp] = timestamp_provider.timestamp
          query_params[:recvWindow] = 5000
        end

        # For GET/DELETE, params go in query string
        if [:get, :delete].include?(request.method)
          query_params.merge!(request.params)
        end

        query_string = URI.encode_www_form(SignatureHelper.format_params(query_params))
        
        if request.signed?
          query_string = SignatureHelper.build_signed_query_for_transport(
            query_params,
            api_key,
            secret_key
          )
        elsif !query_params.empty?
          query_string = URI.encode_www_form(SignatureHelper.format_params(query_params))
        end

        "#{base_url}#{request.path}#{query_string ? "?#{query_string}" : ""}"
      end

      # Build request body for POST/PUT
      # @param request [Request] Request object
      # @return [String, nil] Request body
      def build_body(request)
        return nil if [:get, :delete].include?(request.method)

        case request.encoding
        when :json
          JSON.dump(SignatureHelper.format_params(request.params))
        when :form
          URI.encode_www_form(SignatureHelper.format_params(request.params))
        else
          nil
        end
      end

      # Build request headers
      # @param request [Request] Request object
      # @return [Hash] Headers hash
      def build_headers(request)
        headers = {
          "Content-Type" => content_type(request),
          "X-MBX-APIKEY" => api_key
        }
        headers
      end

      # Get content type based on encoding
      # @param request [Request] Request object
      # @return [String] Content type
      def content_type(request)
        case request.encoding
        when :json
          "application/json"
        when :form
          "application/x-www-form-urlencoded"
        else
          "application/json"
        end
      end

      # Parse response body
      # @param body [String] Raw response body
      # @return [Hash, Array] Parsed JSON
      def parse_body(body)
        JSON.parse(body)
      rescue JSON::ParserError => e
        logger.error("Failed to parse response: #{e.message}")
        raise Errors::ApiError.new(-1, "Invalid JSON response: #{e.message}")
      end

      # Log request details
      # @param request [Request] Request object
      # @param url [String] Full URL
      # @param headers [Hash] Request headers
      def log_request(request, url, headers)
        return unless logger.debug?
        
        safe_params = sanitize_params(request.params)
        logger.debug("[REQUEST] #{request.method_str} #{request.path} params=#{safe_params.inspect}")
      end

      # Sanitize sensitive parameters
      # @param params [Hash] Parameters to sanitize
      # @return [Hash] Sanitized parameters
      def sanitize_params(params)
        params.dup.tap do |p|
          p[:apiKey] = "***REDACTED***" if p.key?(:apiKey)
          p[:signature] = "***REDACTED***" if p.key?(:signature)
        end
      end

      # Default logger
      # @return [Logger]
      def default_logger
        Logger.new($stdout).tap do |log|
          log.level = ENV.fetch("BINANCE_LOG_LEVEL", "WARN").to_sym
        end
      end
    end
  end
end
