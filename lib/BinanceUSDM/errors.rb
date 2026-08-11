# frozen_string_literal: true

module BinanceUSDM
  # Base error class for all BinanceUSDM exceptions.
  class Error < StandardError; end

  # Base class for Binance API errors with detailed context.
  class BinanceError < Error
    attr_reader :code, :message, :http_status, :headers, :endpoint, :request_id, :retry_after

    def initialize(message = nil, code: nil, http_status: nil, headers: nil, endpoint: nil, request_id: nil,
                   retry_after: nil, **kwargs)
      msg = message.is_a?(String) ? message : (kwargs[:message] || 'Binance API Error')
      @code = code || (message.is_a?(Numeric) ? message : kwargs[:code])
      @message = msg
      @http_status = http_status || kwargs[:http_status]
      @headers = (headers || kwargs[:headers] || {}).transform_keys(&:downcase)
      @endpoint = endpoint || kwargs[:endpoint]
      @request_id = request_id || kwargs[:request_id] || @headers['x-mbx-request-id']
      @retry_after = retry_after || kwargs[:retry_after] || @headers['retry-after']&.to_i
      super(msg)
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

  # Raised when the API returns an error response.
  class ApiError < BinanceError; end

  # Raised when authentication fails (invalid API key, signature, etc.)
  class AuthenticationError < BinanceError; end

  # Raised when authorization fails (insufficient permissions)
  class AuthorizationError < BinanceError; end

  # Raised when a request is invalid (bad parameters, missing fields)
  class ValidationError < BinanceError; end

  # Raised when rate limit is exceeded.
  class RateLimitError < BinanceError; end

  # Raised when order-related errors occur.
  class OrderError < BinanceError; end

  # Raised when position-related errors occur.
  class PositionError < BinanceError; end

  # Raised when timestamp is outside recvWindow.
  class TimestampError < BinanceError; end

  # Raised when account has insufficient balance.
  class InsufficientBalanceError < BinanceError; end

  # Raised when symbol is invalid or not found.
  class InvalidSymbolError < BinanceError; end

  # Raised when network connection fails.
  class NetworkError < Error; end

  # Alias for NetworkError
  ConnectionError = NetworkError

  # Raised when request times out.
  class TimeoutError < NetworkError; end

  # Raised when server returns 5xx errors.
  class ServerError < BinanceError; end

  # Error mapping based on Binance error codes
  # See: https://binance-docs.github.io/apidocs/futures/en/#error-codes
  ERROR_CODE_MAP = {
    -1001 => ValidationError,       # INTERNAL_ERROR
    -1002 => ValidationError,       # NOT_CONNECTED
    -1003 => ValidationError,       # UNAUTHORIZED
    -1006 => RateLimitError,        # TIMED_OUT
    -1007 => RateLimitError,        # SERVER_BUSY
    -1014 => ValidationError,       # UNKNOWN_PARAM
    -1015 => RateLimitError,        # TOO_MANY_REQUESTS
    -1020 => ValidationError,       # UNSUPPORTED_PARAM
    -1021 => TimestampError,        # RECV_WINDOW_EXPIRED
    -1022 => AuthenticationError,   # SIGNATURE_ERROR
    -1100 => ValidationError,       # ILLEGAL_CHARS
    -1101 => ValidationError,       # TOO_MANY_PARAMETERS
    -1102 => ValidationError,       # MANDATORY_PARAM_EMPTY
    -1103 => ValidationError,       # UNKNOWN_ORDER_TYPE
    -1104 => ValidationError,       # UNKNOWN_SIDE
    -1105 => ValidationError,       # UNKNOWN_TIF
    -1106 => ValidationError,       # UNKNOWN_ORDER_STATUS
    -1108 => ValidationError,       # INVALID_PRICE
    -1109 => ValidationError,       # INVALID_QTY
    -1111 => OrderError,            # STOP_LIMIT_QTY
    -1112 => OrderError,            # NO_DEPTH
    -1114 => ValidationError,       # TIF_NOT_SUPPORTED
    -1115 => ValidationError,       # INVALID_TICK_SIZE
    -1116 => ValidationError,       # INVALID_LOT_SIZE
    -1117 => ValidationError,       # INVALID_STEP_SIZE
    -1118 => ValidationError,       # INVALID_PRICE_MULTIPLIER
    -1119 => PositionError,         # INVALID_POSITION_SIDE
    -1120 => ValidationError,       # INVALID_ORDER_TYPE
    -1121 => InvalidSymbolError,    # INVALID_SYMBOL
    -1122 => ValidationError,       # INVALID_LISTEN_KEY
    -1125 => ValidationError,       # INVALID_RECVWINDOW
    -1127 => ValidationError,       # MORE_THAN_XX_HOURS
    -1128 => ValidationError,       # OPTIONAL_PARAMS_BAD_COMBO
    -1129 => ValidationError,       # BAD_PARAMETER
    -1130 => ValidationError,       # BAD_VALUE
    -1131 => ValidationError,       # PRICE_LESS_THAN_ZERO
    -1132 => ValidationError,       # PRICE_GREATER_THAN_ZERO
    -1133 => OrderError,            # QTY_LESS_THAN_ZERO
    -1134 => OrderError,            # QTY_GREATER_THAN_ZERO
    -1135 => OrderError,            # NEW_ORDER_REJECTED
    -1136 => OrderError,            # CANCEL_REJECTED
    -1137 => OrderError,            # CANCEL_TOO_MANY_ORDERS
    -1138 => ValidationError,       # INVALID_CLOrderId
    -1139 => OrderError,            # ORDER_ALREADY_CANCELED
    -1140 => OrderError,            # ORDER_DOES_NOT_EXIST
    -1141 => InsufficientBalanceError, # INSUFFICIENT_BALANCE
    -1142 => OrderError,            # DUPLICATE_ORDER
    -1143 => OrderError,            # DUPLICATE_CANCEL
    -1144 => OrderError,            # ORDER_WOULD_TRIGGER_IMMEDIATELY
    -1145 => ValidationError,       # WORKING_TYPE_NOT_SUPPORTED
    -1146 => PositionError,         # POSITION_SIDE_MISMATCH
    -1147 => OrderError,            # REDUCE_ONLY_CONFLICT
    -1148 => OrderError,            # EXCEED_MAX_CANCEL_ORDER_SIZE
    -1149 => ValidationError,       # INVALID_PRICE_MATCH
    -1150 => ValidationError,       # INVALID_SELF_TRADE_PREVENTION_MODE
    -1151 => OrderError,            # STP_REJECT
    -1152 => ValidationError,       # INVALID_ACTIVATION_PRICE
    -1153 => ValidationError,       # INVALID_CALLBACK_RATE
    -2010 => InsufficientBalanceError, # ACCOUNT_HAS_INSUFFICIENT_BALANCE
    -2011 => OrderError,            # ORDER_DOES_NOT_EXIST
    -2013 => OrderError,            # ORDER_NOT_FOUND
    -2014 => AuthenticationError,   # API_KEY_INVALID
    -2015 => AuthenticationError,   # API_KEY_PERMISSIONS
    -2016 => InsufficientBalanceError, # NO_SUCH_USER
    -2019 => InsufficientBalanceError, # NOTIONAL_EXCEEDED
    -2020 => OrderError,            # SUPPORTED_ORDER_TYPES
    -2021 => OrderError,            # REDUCE_ONLY_ORDER_TYPE
    -2022 => ValidationError,       # INVALID_CLIENTOrderId
    -2023 => OrderError,            # UNKNOWN_ORDER
    -2024 => OrderError,            # ORDER_PENDING_MATCH
    -2025 => OrderError,            # ORDER_PENDING_CANCEL
    -2026 => OrderError,            # ORDER_AMEND_FAILED
    -2027 => ValidationError,       # PRICE_NO_CHANGE
    -4001 => ValidationError,       # BROKER_NOT_SUPPPORTED
    -4002 => ValidationError,       # BROKER_INVALID_CHARS
    -4003 => ValidationError,       # BROKER_TOO_LONG
    -4050 => ValidationError,       # INVALID_KLINE_LIMIT
    -4051 => ValidationError,       # INVALID_AGG_TRADE_LIMIT
    -4101 => AuthorizationError,    # IP_UNAUTHORIZED
    -4102 => AuthorizationError,    # ACCOUNT_NOT_FOUND
    -4103 => AuthorizationError,    # ACCOUNT_NOT_ACTIVE
    -4104 => AuthorizationError,    # WITHDRAW_NOT_OPEN
    -4105 => AuthorizationError,    # DEPOSIT_NOT_OPEN
    -4106 => AuthorizationError,    # TRANSFER_NOT_OPEN
    -4107 => AuthorizationError,    # FUTURES_NOT_OPEN
    -4108 => AuthorizationError,    # MARGIN_NOT_OPEN
    -4109 => AuthorizationError,    # SPOT_NOT_OPEN
    -4110 => AuthorizationError,    # OPTION_NOT_OPEN
    -4111 => AuthorizationError,    # PORTFOLIO_MARGIN_NOT_OPEN
    -4112 => AuthorizationError,    # TRADING_GROUP_NOT_FOUND
    -4113 => AuthorizationError,    # TRADING_GROUP_NOT_ACTIVE
    -4114 => AuthorizationError,    # USER_NOT_FOUND
    -4115 => AuthorizationError,    # USER_NOT_ACTIVE
    -4116 => AuthorizationError,    # USER_NOT_ALLOW
    -4117 => AuthorizationError,    # SYMBOL_NOT_FOUND
    -4118 => AuthorizationError,    # SYMBOL_NOT_OPEN
    -4119 => AuthorizationError,    # SYMBOL_NOT_SUPPORT
    -4120 => AuthorizationError,    # SYMBOL_DELISTED
    -4121 => AuthorizationError,    # SYMBOL_SUSPENDED
    -4122 => AuthorizationError,    # SYMBOL_CLOSED
    -4123 => AuthorizationError,    # SYMBOL_FROZEN
    -4124 => AuthorizationError,    # SYMBOL_LOCKED
    -4125 => AuthorizationError,    # SYMBOL_TRADING_HALTED
    -4126 => AuthorizationError,    # SYMBOL_MAINTENANCE
    -4127 => AuthorizationError,    # SYMBOL_OFFLINE
    -4128 => AuthorizationError,    # SYMBOL_POST_ONLY
    -4129 => AuthorizationError,    # SYMBOL_LIMIT_ONLY
    -4130 => AuthorizationError,    # SYMBOL_MARKET_ONLY
    -4131 => AuthorizationError,    # SYMBOL_STOP_ONLY
    -4132 => AuthorizationError,    # SYMBOL_TAKE_PROFIT_ONLY
    -4133 => AuthorizationError,    # SYMBOL_STOP_LOSS_ONLY
    -4134 => AuthorizationError,    # SYMBOL_TRAILING_STOP_ONLY
    -4135 => AuthorizationError,    # SYMBOL_ICEBERG_ONLY
    -4136 => AuthorizationError,    # SYMBOL_TIME_IN_FORCE_ONLY
    -4137 => AuthorizationError,    # SYMBOL_ORDER_TYPE_ONLY
    -4138 => AuthorizationError,    # SYMBOL_SIDE_ONLY
    -4139 => AuthorizationError,    # SYMBOL_POSITION_SIDE_ONLY
    -4140 => AuthorizationError,    # SYMBOL_WORKING_TYPE_ONLY
    -4141 => AuthorizationError,    # SYMBOL_PRICE_PROTECT_ONLY
    -4142 => AuthorizationError,    # SYMBOL_PRICE_MATCH_ONLY
    -4143 => AuthorizationError,    # SYMBOL_SELF_TRADE_PREVENTION_MODE_ONLY
    -4144 => AuthorizationError,    # SYMBOL_GOOD_TILL_DATE_ONLY
    -4145 => AuthorizationError,    # SYMBOL_CLOSE_POSITION_ONLY
    -4146 => AuthorizationError,    # SYMBOL_ACTIVATE_ONLY
    -4147 => AuthorizationError     # SYMBOL_CALLBACK_ONLY
  }.freeze

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

  Errors = self
end
