# frozen_string_literal: true

require "faraday"
require "json"
require "logger"

module BinanceUSDM
  # HTTP client for making API requests to Binance.
  class Client
    attr_reader :api_key, :secret_key, :testnet, :logger
    
    # Initialize the HTTP client
    # @param api_key [String] Binance API key
    # @param secret_key [String] Binance API secret
    # @param testnet [Boolean] Use testnet (default: false)
    # @param logger [Logger] Custom logger (optional)
    def initialize(api_key:, secret_key:, testnet: false, logger: nil)
      @api_key = api_key
      @secret_key = secret_key
      @testnet = testnet
      @logger = logger || default_logger
      @base_url = testnet ? Constants::Urls::TESTNET_REST_API_BASE : Constants::Urls::REST_API_BASE
    end
    
    # Perform GET request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Query parameters
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @return [Hash, Array] Parsed JSON response
    def get(endpoint, params: {}, signed: true)
      request(:get, endpoint, params, signed)
    end
    
    # Perform POST request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @return [Hash, Array] Parsed JSON response
    def post(endpoint, params: {}, signed: true)
      request(:post, endpoint, params, signed)
    end
    
    # Perform PUT request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @return [Hash, Array] Parsed JSON response
    def put(endpoint, params: {}, signed: true)
      request(:put, endpoint, params, signed)
    end
    
    # Perform DELETE request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Query parameters
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @return [Hash, Array] Parsed JSON response
    def delete(endpoint, params: {}, signed: true)
      request(:delete, endpoint, params, signed)
    end
    
    private
    
    # Perform HTTP request with error handling
    # @param method [Symbol] HTTP method
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request parameters
    # @param signed [Boolean] Whether request requires signature
    # @return [Hash, Array] Parsed JSON response
    # @raise [ApiError, AuthenticationError, RateLimitError]
    def request(method, endpoint, params, signed)
      url = build_url(endpoint, params, signed)
      headers = build_headers
      
      log_request(method, endpoint, params, signed)
      
      response = connection.send(method, url, nil, headers)
      handle_response(response)
    rescue Faraday::ConnectionFailed => e
      logger.error("Connection failed: #{e.message}")
      raise ConnectionError, "Failed to connect to Binance API: #{e.message}"
    rescue Faraday::TimeoutError => e
      logger.error("Request timeout: #{e.message}")
      raise ConnectionError, "Request timeout: #{e.message}"
    end
    
    # Build connection with Faraday
    # @return [Faraday::Connection]
    def connection
      @connection ||= Faraday.new do |conn|
        conn.adapter :net_http
        conn.options.timeout = 30
        conn.options.open_timeout = 10
      end
    end
    
    # Build full URL with query string
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request parameters
    # @param signed [Boolean] Whether to sign the request
    # @return [String] Full URL with query string
    def build_url(endpoint, params, signed)
      formatted_params = SignatureHelper.format_params(params)
      
      if signed
        query_string = SignatureHelper.build_signed_query(
          formatted_params,
          api_key,
          secret_key
        )
      else
        query_string = URI.encode_www_form(formatted_params) unless formatted_params.empty?
      end
      
      "#{@base_url}#{endpoint}#{query_string ? "?#{query_string}" : ""}"
    end
    
    # Build request headers
    # @return [Hash] Headers hash
    def build_headers
      {
        "Content-Type" => "application/json",
        "X-MBX-APIKEY" => api_key
      }
    end
    
    # Handle API response
    # @param response [Faraday::Response]
    # @return [Hash, Array] Parsed JSON
    # @raise [ApiError, AuthenticationError, RateLimitError, InvalidRequestError]
    def handle_response(response)
      data = JSON.parse(response.body)
      
      log_response(response.status, data)
      
      # Check for error in response
      if data.is_a?(Hash) && data["code"]
        raise_error(data["code"], data["msg"], data)
      end
      
      data
    rescue JSON::ParserError => e
      logger.error("Failed to parse response: #{e.message}")
      raise ApiError, "Invalid JSON response: #{e.message}"
    end
    
    # Raise appropriate error based on code
    # @param code [Integer] Error code
    # @param message [String] Error message
    # @param response [Hash] Full response
    def raise_error(code, message, response)
      case code
      when -1001, -1002, -1003
        raise InvalidRequestError, "Binance API error #{code}: #{message}"
      when -1006, -1007
        raise RateLimitError, "Rate limit exceeded: #{message}"
      when -1021, -1022
        raise AuthenticationError, "Authentication failed: #{message}"
      when -2014
        raise AuthenticationError, "API key authentication failed: #{message}"
      else
        raise ApiError.new(code, "Binance API error #{code}: #{message}", response)
      end
    end
    
    # Log request details
    # @param method [Symbol] HTTP method
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request parameters
    # @param signed [Boolean] Whether signed
    def log_request(method, endpoint, params, signed)
      return unless logger.debug?
      
      safe_params = sanitize_params(params)
      logger.debug("[REQUEST] #{method.to_s.upcase} #{endpoint} params=#{safe_params.inspect} signed=#{signed}")
    end
    
    # Log response details
    # @param status [Integer] HTTP status code
    # @param data [Hash, Array] Response data
    def log_response(status, data)
      return unless logger.debug?
      
      logger.debug("[RESPONSE] Status=#{status} body=#{data.inspect[0..500]}")
    end
    
    # Sanitize sensitive parameters for logging
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
