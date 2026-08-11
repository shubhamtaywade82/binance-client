# frozen_string_literal: true

require "faraday"
require "json"
require "logger"
require_relative "../transport/http"
require_relative "../transport/request"
require_relative "../transport/endpoint"
require_relative "../authentication/clock"
require_relative "../rate_limit/manager"

module BinanceUSDM
  # HTTP client for making API requests to Binance.
  class Client
    attr_reader :api_key, :secret_key, :testnet, :logger, :clock, :rate_limiter
    
    # Initialize the HTTP client
    # @param api_key [String] Binance API key
    # @param secret_key [String] Binance API secret
    # @param testnet [Boolean] Use testnet (default: false)
    # @param logger [Logger] Custom logger (optional)
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    def initialize(api_key:, secret_key:, testnet: false, logger: nil, timeout: 30)
      @api_key = api_key
      @secret_key = secret_key
      @testnet = testnet
      @logger = logger || default_logger
      @base_url = testnet ? Constants::Urls::TESTNET_REST_API_BASE : Constants::Urls::REST_API_BASE
      
      # Initialize clock for time synchronization
      @clock = Authentication::Clock.new
      @auto_sync_time = true
      
      # Initialize rate limiter
      @rate_limiter = RateLimit::Manager.new
      
      # Initialize HTTP transport
      @http = Transport::HTTP.new(
        base_url: @base_url,
        api_key: api_key,
        secret_key: secret_key,
        timeout: timeout,
        logger: logger
      )
    end
    
    # Enable/disable automatic time synchronization
    attr_accessor :auto_sync_time
    
    # Get server time offset
    # @return [Integer] Time offset in milliseconds
    def time_offset
      clock.time_offset
    end
    
    # Get last server time sync timestamp
    # @return [Time, nil]
    def server_time
      clock.now
    end
    
    # Synchronize time with Binance server
    # @raise [NetworkError] if sync fails
    def sync_time!
      response = @http.execute(
        Transport::Request.new(
          method: :get,
          path: "/fapi/v1/time",
          security: :market,
          encoding: :query
        )
      )
      
      server_time_ms = response.body["serverTime"]
      clock.sync(server_time_ms)
      
      logger.info("Time synchronized with Binance server: offset=#{clock.offset_str}")
      server_time_ms
    rescue => e
      logger.error("Failed to sync time: #{e.message}")
      raise
    end
    
    # Perform GET request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Query parameters
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @param security [Symbol] Security type (:trade, :user_data, :market)
    # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
    # @return [Hash, Array] Parsed JSON response
    def get(endpoint, params: {}, signed: true, security: nil, encoding: :query)
      request(:get, endpoint, params, signed, security, encoding)
    end
    
    # Perform POST request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @param security [Symbol] Security type (:trade, :user_data, :market)
    # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
    # @return [Hash, Array] Parsed JSON response
    def post(endpoint, params: {}, signed: true, security: nil, encoding: :form)
      request(:post, endpoint, params, signed, security, encoding)
    end
    
    # Perform PUT request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @param security [Symbol] Security type (:trade, :user_data, :market)
    # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
    # @return [Hash, Array] Parsed JSON response
    def put(endpoint, params: {}, signed: true, security: nil, encoding: :form)
      request(:put, endpoint, params, signed, security, encoding)
    end
    
    # Perform DELETE request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Query parameters
    # @param signed [Boolean] Whether request requires signature (default: true)
    # @param security [Symbol] Security type (:trade, :user_data, :market)
    # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
    # @return [Hash, Array] Parsed JSON response
    def delete(endpoint, params: {}, signed: true, security: nil, encoding: :query)
      request(:delete, endpoint, params, signed, security, encoding)
    end
    
    # Execute request with endpoint spec
    # @param endpoint_spec [Transport::EndpointSpec] Endpoint specification
    # @param params [Hash] Request parameters
    # @return [Hash, Array] Parsed JSON response
    def execute(endpoint_spec, params = {})
      request_obj = endpoint_spec.build_request(params)
      
      # Auto-sync time if enabled
      if auto_sync_time && clock.sync_needed? && request_obj.signed?
        begin
          sync_time!
        rescue => e
          logger.warn("Auto time sync failed: #{e.message}")
        end
      end
      
      # Check rate limits
      unless rate_limiter.allow?(endpoint_spec)
        logger.warn("Rate limit exceeded for #{endpoint_spec.path}")
        raise Errors::RateLimitError, "Rate limit exceeded"
      end
      
      # Execute request
      response = @http.execute(request_obj, timestamp_provider: clock)
      
      # Update rate limiter from headers
      rate_limiter.update_from_headers(response.headers)
      
      # Handle error responses
      handle_response_body(response.body, response.status, response.headers, endpoint_spec.path)
      
      response.body
    end
    
    private
    
    # Perform HTTP request with error handling
    # @param method [Symbol] HTTP method
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request parameters
    # @param signed [Boolean] Whether request requires signature
    # @param security [Symbol] Security type
    # @param encoding [Symbol] Parameter encoding
    # @return [Hash, Array] Parsed JSON response
    def request(method, endpoint, params, signed, security, encoding)
      security ||= (signed ? :trade : :market)
      
      request_obj = Transport::Request.new(
        method: method,
        path: endpoint,
        params: params,
        security: security,
        encoding: encoding
      )
      
      # Auto-sync time if enabled
      if auto_sync_time && clock.sync_needed? && request_obj.signed?
        begin
          sync_time!
        rescue => e
          logger.warn("Auto time sync failed: #{e.message}")
        end
      end
      
      # Execute request
      response = @http.execute(request_obj, timestamp_provider: clock)
      
      # Update rate limiter from headers
      rate_limiter.update_from_headers(response.headers)
      
      # Handle error responses
      handle_response_body(response.body, response.status, response.headers, endpoint)
      
      response.body
    rescue Faraday::ConnectionFailed => e
      logger.error("Connection failed: #{e.message}")
      raise Errors::ConnectionError, "Failed to connect to Binance API: #{e.message}"
    rescue Faraday::TimeoutError => e
      logger.error("Request timeout: #{e.message}")
      raise Errors::TimeoutError, "Request timeout: #{e.message}"
    end
    
    # Handle response body and raise errors if needed
    # @param body [Hash, Array] Response body
    # @param status [Integer] HTTP status code
    # @param headers [Hash] Response headers
    # @param endpoint [String] API endpoint
    def handle_response_body(body, status, headers, endpoint)
      return unless body.is_a?(Hash) && body["code"]
      
      code = body["code"]
      message = body["msg"] || "Unknown error"
      
      error = BinanceUSDM.create_error(
        code: code,
        message: message,
        http_status: status,
        headers: headers,
        endpoint: endpoint
      )
      
      logger.error("[API ERROR] #{error.class}: #{message} (code: #{code})")
      raise error
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
