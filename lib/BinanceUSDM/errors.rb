# frozen_string_literal: true

module BinanceUSDM
  # Base error class for all BinanceUSDM exceptions.
  class Error < StandardError; end

  # Raised when the API returns an error response.
  class ApiError < Error
    attr_reader :code, :response

    def initialize(code, message, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  # Raised when authentication fails.
  class AuthenticationError < Error; end

  # Raised when a request is invalid.
  class InvalidRequestError < Error; end

  # Raised when rate limit is exceeded.
  class RateLimitError < Error; end

  # Raised when connection to WebSocket fails.
  class ConnectionError < Error; end
end
