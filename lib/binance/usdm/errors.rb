# frozen_string_literal: true

# Error classes and code mappings for Binance API failures.
module Binance
  # USD-M Futures API error classes.
  module USDM
    # Base error class for all Binance::USDM exceptions.
    class Error < StandardError; end

    # Base class for Binance API errors with detailed context.
    class BinanceError < Error
      attr_reader :code, :message, :http_status, :headers, :endpoint, :request_id, :retry_after

      # Initialize error with optional positional message and keyword context.
      def initialize(message = nil, **options)
        @code = extract_code(message, options)
        @message = extract_message(message, options)
        @http_status = options[:http_status]
        @headers = (options[:headers] || {}).transform_keys(&:downcase)
        @endpoint = options[:endpoint]
        @request_id = options[:request_id] || @headers['x-mbx-request-id']
        @retry_after = options[:retry_after] || @headers['retry-after']&.to_i
        super(@message)
      end

      def to_h
        {
          code: code,
          message: message,
          http_status: http_status,
          endpoint: endpoint,
          request_id: request_id,
          retry_after: retry_after
        }.compact
      end

      private

      def extract_code(message, options)
        return options[:code] if options[:code]
        return message if message.is_a?(Numeric)

        nil
      end

      def extract_message(message, options)
        return message if message.is_a?(String)
        return options[:message] if options[:message]

        'Binance API Error'
      end
    end

    # Raised when the API returns an error response.
    # Base class for all specific API errors (AuthenticationError, ValidationError, etc.).
    class ApiError < BinanceError; end

    # Raised when authentication fails (invalid API key, signature, etc.)
    class AuthenticationError < ApiError; end

    # Raised when authorization fails (insufficient permissions)
    class AuthorizationError < ApiError; end

    # Raised when a request is invalid (bad parameters, missing fields)
    class ValidationError < ApiError; end

    # Raised when rate limit is exceeded.
    class RateLimitError < ApiError; end

    # Raised when order-related errors occur.
    class OrderError < ApiError; end

    # Raised when position-related errors occur.
    class PositionError < ApiError; end

    # Raised when timestamp is outside recvWindow.
    class TimestampError < ApiError; end

    # Raised when account has insufficient balance.
    class InsufficientBalanceError < ApiError; end

    # Raised when symbol is invalid or not found.
    class InvalidSymbolError < ApiError; end

    # Raised when network connection fails.
    class NetworkError < Error; end

    # Alias for NetworkError
    ConnectionError = NetworkError

    # Raised when request times out.
    class TimeoutError < NetworkError; end

    # Raised when server returns 5xx errors.
    class ServerError < ApiError; end

    require_relative 'errors/error_code_map'

    # Combined mapping of all Binance error codes to error classes.
    ERROR_CODE_MAP = ErrorCodesCore::CODES.merge(ErrorCodesAccount::CODES).freeze

    # Get error class for a given Binance error code
    # @param code [Integer] Binance error code
    # @return [Class] Error class
    def self.error_class_for_code(code)
      ERROR_CODE_MAP[code] || ApiError
    end

    # Create appropriate error from response data
    # @param code [Integer] Error code
    # @param message [String] Error message
    # @param http_status [Integer] HTTP status
    # @param headers [Hash] Response headers
    # @param endpoint [String] API endpoint
    # @return [BinanceError] Appropriate error instance
    def self.create_error(code:, message:, http_status: nil, headers: nil, endpoint: nil)
      error_class = error_class_for_code(code)
      error_class.new(
        code: code,
        message: message,
        http_status: http_status,
        headers: headers,
        endpoint: endpoint
      )
    end
  end
end
