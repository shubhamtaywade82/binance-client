# frozen_string_literal: true

module BinanceUSDM
  # Constants used throughout the library.
  module Constants
    # API URLs for Binance USD-M Futures
    module Urls
      REST_API_BASE = 'https://fapi.binance.com'
      TESTNET_REST_API_BASE = 'https://testnet.binancefuture.com'
      WEBSOCKET_BASE = 'wss://fstream.binance.com'
      WEBSOCKET_TESTNET_BASE = 'wss://stream.binancefuture.com'

      API_VERSION = 'v1'
    end

    # HTTP methods
    HTTP_METHODS = {
      GET: 'GET',
      POST: 'POST',
      PUT: 'PUT',
      DELETE: 'DELETE'
    }.freeze

    # Order types
    ORDER_TYPES = %w[
      LIMIT
      MARKET
      STOP
      STOP_MARKET
      TAKE_PROFIT
      TAKE_PROFIT_MARKET
      TRAILING_STOP_MARKET
    ].freeze

    # Order sides
    ORDER_SIDES = %w[BUY SELL].freeze

    # Position sides
    POSITION_SIDES = %w[BOTH LONG SHORT].freeze

    # Time in force
    TIME_IN_FORCE = %w[GTC IOC FOK].freeze

    # Product types
    PRODUCT_TYPES = {
      PERPETUAL: 'PERPETUAL',
      CURRENT_MONTH: 'CURRENT_MONTH',
      NEXT_MONTH: 'NEXT_MONTH',
      CURRENT_QUARTER: 'CURRENT_QUARTER',
      NEXT_QUARTER: 'NEXT_QUARTER'
    }.freeze
  end
end
