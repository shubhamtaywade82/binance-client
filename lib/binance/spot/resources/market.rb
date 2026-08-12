# frozen_string_literal: true

require_relative 'base'
require_relative '../models'

module Binance
  module Spot
    module Resources
      # Public Spot market data endpoints. No signature required.
      class Market < Base
        def ping
          @api.request(:get_api_v3_ping)
        end

        def server_time
          @api.request(:get_api_v3_time)
        end

        def exchange_info(symbol: nil, symbols: nil)
          params = {}
          params[:symbol] = symbol if symbol
          params[:symbols] = symbols.to_json if symbols

          @api.request(:get_api_v3_exchangeinfo, params)
        end

        def depth(symbol:, limit: 100)
          @api.request(:get_api_v3_depth, symbol: symbol, limit: limit)
        end

        def trades(symbol:, limit: 500)
          @api.request(:get_api_v3_trades, symbol: symbol, limit: limit)
        end

        def historical_trades(symbol:, limit: 500, from_id: nil)
          params = { symbol: symbol, limit: limit }
          params[:fromId] = from_id if from_id

          @api.request(:get_api_v3_historicaltrades, params)
        end

        def agg_trades(symbol:, from_id: nil, start_time: nil, end_time: nil, limit: 500)
          params = timed_params({ symbol: symbol, limit: limit }, start_time, end_time)
          params[:fromId] = from_id if from_id

          @api.request(:get_api_v3_aggtrades, params)
        end

        def klines(symbol:, interval:, start_time: nil, end_time: nil, limit: 500)
          params = timed_params({ symbol: symbol, interval: interval, limit: limit }, start_time, end_time)

          @api.request(:get_api_v3_klines, params)
        end

        def ui_klines(symbol:, interval:, start_time: nil, end_time: nil, limit: 500)
          params = timed_params({ symbol: symbol, interval: interval, limit: limit }, start_time, end_time)

          @api.request(:get_api_v3_uiklines, params)
        end

        def avg_price(symbol:)
          @api.request(:get_api_v3_avgprice, symbol: symbol)
        end

        # Get historical block trades (large off-book trades)
        def historical_block_trades(symbol:, limit: 500)
          @api.request(:get_api_v3_historicalblocktrades, symbol: symbol, limit: limit)
        end

        # Get order entry rules (min/max notional, filters) for a symbol
        def execution_rules(symbol:)
          @api.request(:get_api_v3_executionrules, symbol: symbol)
        end

        # Get the current reference price for a symbol
        def reference_price(symbol:)
          @api.request(:get_api_v3_referenceprice, symbol: symbol)
        end

        # Get the reference price calculation detail for a symbol
        def reference_price_calculation(symbol:)
          @api.request(:get_api_v3_referenceprice_calculation, symbol: symbol)
        end

        def ticker_24h(symbol: nil, symbols: nil, type: nil)
          response = @api.request(:get_api_v3_ticker_24hr, ticker_params(symbol, symbols, type))
          wrap_ticker(response)
        end

        def ticker_trading_day(symbol: nil, symbols: nil, time_zone: nil)
          params = ticker_params(symbol, symbols, nil)
          params[:timeZone] = time_zone if time_zone

          @api.request(:get_api_v3_ticker_tradingday, params)
        end

        def rolling_window_ticker(symbol: nil, symbols: nil, window_size: nil, type: nil)
          params = ticker_params(symbol, symbols, type)
          params[:windowSize] = window_size if window_size

          @api.request(:get_api_v3_ticker, params)
        end

        def ticker_price(symbol: nil, symbols: nil)
          @api.request(:get_api_v3_ticker_price, ticker_params(symbol, symbols, nil))
        end

        def book_ticker(symbol: nil, symbols: nil)
          @api.request(:get_api_v3_ticker_bookticker, ticker_params(symbol, symbols, nil))
        end

        private

        def ticker_params(symbol, symbols, type)
          params = {}
          params[:symbol] = symbol if symbol
          params[:symbols] = symbols.to_json if symbols
          params[:type] = type if type
          params
        end

        def wrap_ticker(response)
          response.is_a?(Array) ? response.map { |t| Models::Ticker.new(t) } : Models::Ticker.new(response)
        end

        def timed_params(base, start_time, end_time)
          base[:startTime] = start_time if start_time
          base[:endTime] = end_time if end_time
          base
        end
      end
    end
  end
end
