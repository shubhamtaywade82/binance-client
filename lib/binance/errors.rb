# frozen_string_literal: true

module Binance
  # Base error class for all Binance exceptions
  class Error < StandardError; end
  
  # Base class for Binance API errors with detailed context
  class BinanceError < Error
    attr_reader :code, :message, :http_status, :headers, :endpoint, :request_id, :retry_after
    
    def initialize(code: nil, message:, http_status: nil, headers: nil, endpoint: nil, request_id: nil, retry_after: nil)
      @code = code
      @message = message
      @http_status = http_status
      @headers = (headers || {}).transform_keys(&:downcase)
      @endpoint = endpoint
      @request_id = request_id || @headers["x-mbx-request-id"]
      @retry_after = retry_after || @headers["retry-after"]&.to_i
      super(message)
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
  
  # Reuse the existing error mapping from BinanceUSDM
  ERROR_CODE_MAP = BinanceUSDM::ERROR_CODE_MAP if defined?(BinanceUSDM)
  
  def self.error_class_for_code(code)
    ERROR_CODE_MAP[code] || ApiError
  end
  
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
