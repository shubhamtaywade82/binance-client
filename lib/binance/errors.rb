# frozen_string_literal: true

# Error classes and code mappings for the Binance SDK.
module Binance
  # Base error class for all Binance exceptions
  class Error < StandardError; end

  # Base class for Binance API errors with detailed context
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

  class ApiError < BinanceError; end
  class AuthenticationError < BinanceError; end
  class AuthorizationError < BinanceError; end
  class ValidationError < BinanceError; end
  class RateLimitError < BinanceError; end
  class OrderError < BinanceError; end
  class PositionError < BinanceError; end
  class TimestampError < BinanceError; end
  class InsufficientBalanceError < BinanceError; end
  class InvalidSymbolError < BinanceError; end
  class NetworkError < Error; end
  ConnectionError = NetworkError
  class TimeoutError < NetworkError; end
  class ServerError < BinanceError; end

  # Mapping of Binance error codes to error classes (from Binance::USDM)
  def self.error_map
    defined?(Binance::USDM::ERROR_CODE_MAP) ? Binance::USDM::ERROR_CODE_MAP : {}
  end

  # Get error class for a given Binance error code
  def self.error_class_for_code(code)
    error_map[code] || ApiError
  end

  # Create appropriate error from response data
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
