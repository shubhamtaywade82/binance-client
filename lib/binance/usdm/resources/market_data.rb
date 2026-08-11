# frozen_string_literal: true

require_relative '../core/base_api'

module Binance
  module USDM
    module Resources
      # Auxiliary public USDⓈ-M Futures market data endpoints not covered by Market.
      # All endpoints here require no signature.
      class MarketData < BaseAPI
        # Test connectivity to the REST API
        # @return [Hash] Empty response if successful
        def ping
          get('/fapi/v1/ping', params: {}, signed: false)
        end

        # Get server time
        # @return [Hash] Server time in ms
        def server_time
          get('/fapi/v1/time', params: {}, signed: false)
        end

        # Get compressed/aggregate trades
        # @param symbol [String] Trading symbol
        # @param from_id [Integer, nil] Trade ID to fetch from
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of trades (default: 500, max: 1000)
        # @return [Array<Hash>] Aggregate trades
        def agg_trades(symbol:, from_id: nil, start_time: nil, end_time: nil, limit: 500)
          params = timed_params({ symbol: symbol, limit: limit }, start_time, end_time)
          params[:fromId] = from_id if from_id

          get('/fapi/v1/aggTrades', params: params, signed: false)
        end

        # Get continuous contract klines
        # @param pair [String] Pair (e.g., "BTCUSDT")
        # @param contract_type [String] PERPETUAL, CURRENT_QUARTER, NEXT_QUARTER
        # @param interval [String] Kline interval
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of candles (default: 500, max: 1500)
        # @return [Array<Array>] Continuous contract klines
        def continuous_klines(pair:, contract_type:, interval:, start_time: nil, end_time: nil, limit: 500)
          params = timed_params(
            { pair: pair, contractType: contract_type, interval: interval, limit: limit }, start_time, end_time
          )

          get('/fapi/v1/continuousKlines', params: params, signed: false)
        end

        # Get premium index klines
        # @param symbol [String] Trading symbol
        # @param interval [String] Kline interval
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of candles (default: 500, max: 1500)
        # @return [Array<Array>] Premium index klines
        def premium_index_klines(symbol:, interval:, start_time: nil, end_time: nil, limit: 500)
          params = timed_params({ symbol: symbol, interval: interval, limit: limit }, start_time, end_time)

          get('/fapi/v1/premiumIndexKlines', params: params, signed: false)
        end

        # Get composite index symbol information
        # @param symbol [String, nil] Trading symbol (optional)
        # @return [Hash, Array<Hash>] Composite index info
        def index_info(symbol: nil)
          get('/fapi/v1/indexInfo', params: optional_symbol_params(symbol), signed: false)
        end

        # Get funding rate info (caps, floors, intervals) for all symbols
        # @return [Array<Hash>] Funding rate info
        def funding_info
          get('/fapi/v1/fundingInfo', params: {}, signed: false)
        end

        # Get multi-assets mode asset index
        # @param symbol [String, nil] Asset pair (optional, e.g. "ADAUSD")
        # @return [Hash, Array<Hash>] Asset index
        def asset_index(symbol: nil)
          get('/fapi/v1/assetIndex', params: optional_symbol_params(symbol), signed: false)
        end

        # Get basis data (spread between futures and index price)
        # @param pair [String] Pair (e.g., "BTCUSDT")
        # @param contract_type [String] PERPETUAL, CURRENT_QUARTER, NEXT_QUARTER
        # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of results (default: 30, max: 500)
        # @return [Array<Hash>] Basis data
        def basis(pair:, contract_type:, period:, start_time: nil, end_time: nil, limit: 30)
          params = timed_params(
            { pair: pair, contractType: contract_type, period: period, limit: limit }, start_time, end_time
          )

          get('/futures/data/basis', params: params, signed: false)
        end

        # Get quarterly contract settlement (delivery) price
        # @param pair [String] Pair (e.g., "BTCUSDT")
        # @return [Array<Hash>] Delivery prices
        def delivery_price(pair:)
          get('/futures/data/delivery-price', params: { pair: pair }, signed: false)
        end

        # Get index price constituents for a symbol
        # @param symbol [String] Trading symbol
        # @return [Hash] Index price constituents
        def constituents(symbol:)
          get('/fapi/v1/constituents', params: { symbol: symbol }, signed: false)
        end

        # Get insurance fund balance snapshot
        # @param symbol [String, nil] Trading symbol (optional)
        # @return [Hash] Insurance fund balance
        def insurance_balance(symbol: nil)
          get('/fapi/v1/insuranceBalance', params: optional_symbol_params(symbol), signed: false)
        end

        # Get order book including RPI (Retail Price Improvement) orders
        # @param symbol [String] Trading symbol
        # @param limit [Integer] Limit of results (only 1000 is valid, default: 1000)
        # @return [Hash] Order book with bids and asks
        def rpi_depth(symbol:, limit: 1000)
          get('/fapi/v1/rpiDepth', params: { symbol: symbol, limit: limit }, signed: false)
        end

        # Get best bid/ask price and quantity
        # @param symbol [String, nil] Trading symbol (optional)
        # @return [Hash, Array<Hash>] Book ticker
        def book_ticker(symbol: nil)
          get('/fapi/v1/ticker/bookTicker', params: optional_symbol_params(symbol), signed: false)
        end

        # Get latest price for a symbol or all symbols (V2)
        # @param symbol [String, nil] Trading symbol (optional)
        # @return [Hash, Array<Hash>] Latest prices
        def ticker_price_v2(symbol: nil)
          get('/fapi/v2/ticker/price', params: optional_symbol_params(symbol), signed: false)
        end

        # Get top trader long/short position ratio
        # @param symbol [String] Trading symbol
        # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of results (default: 30, max: 500)
        # @return [Array<Hash>] Top trader long/short position ratio
        def top_long_short_position_ratio(symbol:, period:, start_time: nil, end_time: nil, limit: 30)
          params = timed_params({ symbol: symbol, period: period, limit: limit }, start_time, end_time)

          get('/futures/data/topLongShortPositionRatio', params: params, signed: false)
        end

        # Get futures trading schedule (maintenance/trading windows)
        # @return [Hash] Trading schedule
        def trading_schedule
          get('/fapi/v1/tradingSchedule', params: {}, signed: false)
        end

        # Get ADL (Auto-Deleverage) risk for a symbol
        # @param symbol [String] Trading symbol
        # @return [Hash] ADL risk
        def symbol_adl_risk(symbol:)
          get('/fapi/v1/symbolAdlRisk', params: { symbol: symbol }, signed: false)
        end

        private

        def optional_symbol_params(symbol)
          symbol ? { symbol: symbol } : {}
        end

        def timed_params(base, start_time = nil, end_time = nil)
          base[:startTime] = start_time if start_time
          base[:endTime] = end_time if end_time
          base
        end
      end
    end
  end
end
