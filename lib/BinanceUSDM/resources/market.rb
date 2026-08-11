# frozen_string_literal: true

require_relative "../core/base_api"
require_relative "../models"

module BinanceUSDM
  module Resources
    # Market data resource for fetching market information.
    # Supports both instance methods (via client) and class methods (via default_client).
    class Market < BaseAPI
      # Class methods for ORM/ActiveRecord-style usage
      class << self
        # Get the client to use (thread-local or default)
        def client
          Thread.current[:binance_usdm_client] || BinanceUSDM.default_client
        end
        
        # Execute with a specific client
        def using(client_instance)
          previous = Thread.current[:binance_usdm_client]
          Thread.current[:binance_usdm_client] = client_instance
          yield
        ensure
          Thread.current[:binance_usdm_client] = previous
        end
        
        # Get 24hr ticker price change statistics (class method)
        # @example BinanceUSDM::Resources::Market.ticker_24h(symbol: "ETHUSDT")
        def ticker_24h(symbol: nil)
          symbol ? client.market.ticker_24h(symbol: symbol) : client.market.ticker_24h
        end
        
        # Get latest price (class method)
        # @example BinanceUSDM::Resources::Market.price("ETHUSDT")
        def price(symbol = nil)
          result = client.market.prices(symbol: symbol)
          symbol ? result["price"] : result
        end
        
        # Get current order book depth (class method)
        # @example BinanceUSDM::Resources::Market.depth(symbol: "ETHUSDT", limit: 20)
        def depth(symbol:, limit: 100)
          client.market.depth(symbol: symbol, limit: limit)
        end
        
        # Get recent trades (class method)
        # @example BinanceUSDM::Resources::Market.recent_trades(symbol: "ETHUSDT")
        def recent_trades(symbol:, limit: 500)
          client.market.trades(symbol: symbol, limit: limit)
        end
        
        # Get kline/candlestick data (class method)
        # @example BinanceUSDM::Resources::Market.klines(symbol: "ETHUSDT", interval: "1m", limit: 100)
        def klines(symbol:, interval:, limit: 500, start_time: nil, end_time: nil)
          client.market.klines(symbol: symbol, interval: interval, limit: limit, start_time: start_time, end_time: end_time)
        end
        
        # Get current average price (class method)
        # @example BinanceUSDM::Resources::Market.avg_price(symbol: "ETHUSDT")
        def avg_price(symbol:)
          client.market.avg_price(symbol: symbol)
        end
        
        # Get premium index (class method)
        # @example BinanceUSDM::Resources::Market.premium_index(symbol: "ETHUSDT")
        def premium_index(symbol: nil)
          client.market.premium_index(symbol: symbol)
        end
        
        # Get funding rate history (class method)
        # @example BinanceUSDM::Resources::Market.funding_rate_history(symbol: "ETHUSDT")
        def funding_rate_history(symbol:, limit: 100, start_time: nil, end_time: nil)
          client.market.funding_rate_history(symbol: symbol, limit: limit, start_time: start_time, end_time: end_time)
        end
        
        # Get open interest (class method)
        # @example BinanceUSDM::Resources::Market.open_interest(symbol: "ETHUSDT")
        def open_interest(symbol:)
          client.market.open_interest(symbol: symbol)
        end
        
        # Get exchange info (class method)
        # @example BinanceUSDM::Resources::Market.exchange_info
        def exchange_info
          client.market.exchange_info
        end
        
        # Get all instruments/symbols (class method)
        # @example BinanceUSDM::Resources::Market.instruments
        def instruments
          client.market.instruments
        end
        
        # Find a specific symbol by name
        # @example BinanceUSDM::Resources::Market.find_symbol("ETHUSDT")
        def find_symbol(symbol_name)
          instruments.find { |s| s["symbol"] == symbol_name }
        end
      end
      
      # Get 24hr ticker price change statistics
      # @param symbol [String] Trading symbol (optional, all symbols if not provided)
      # @return [Models::Ticker, Array<Models::Ticker>] Ticker statistics
      def ticker_24h(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        response = get("/fapi/v1/ticker/24hr", params: params, signed: false)
        
        if symbol
          Models::Ticker.new(response)
        else
          response.map { |ticker_data| Models::Ticker.new(ticker_data) }
        end
      end
      
      # Get latest price for a symbol or all symbols
      # @param symbol [String] Trading symbol (optional)
      # @return [Hash, Array<Hash>] Latest prices
      def prices(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        get("/fapi/v1/ticker/price", params: params, signed: false)
      end
      
      # Get current order book
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Limit of results (default: 100, max: 5000)
      # @return [Hash] Order book with bids and asks
      def depth(symbol:, limit: 100)
        get("/fapi/v1/depth", params: { symbol: symbol, limit: limit }, signed: false)
      end
      
      # Get recent trades
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Number of trades (default: 500, max: 1000)
      # @return [Array<Hash>] Recent trades
      def trades(symbol:, limit: 500)
        get("/fapi/v1/trades", params: { symbol: symbol, limit: limit }, signed: false)
      end
      
      # Get historical trades
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Number of trades (default: 500, max: 1000)
      # @param from_id [Integer] Trade ID to fetch from (optional)
      # @return [Array<Hash>] Historical trades
      def historical_trades(symbol:, limit: 500, from_id: nil)
        params = { symbol: symbol, limit: limit }
        params[:fromId] = from_id if from_id
        
        get("/fapi/v1/historicalTrades", params: params, signed: false)
      end
      
      # Get kline/candlestick data
      # @param symbol [String] Trading symbol
      # @param interval [String] Kline interval: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M
      # @param limit [Integer] Number of candles (default: 500, max: 1500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Array>] Klines (open_time, open, high, low, close, volume, ...)
      def klines(symbol:, interval:, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          interval: interval,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/klines", params: params, signed: false)
      end
      
      # Get index price klines
      # @param pair [String] Pair (e.g., "BTCUSDT")
      # @param interval [String] Kline interval
      # @param limit [Integer] Number of candles (default: 500, max: 1500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Array>] Index price klines
      def index_price_klines(pair:, interval:, limit: 500, start_time: nil, end_time: nil)
        params = {
          pair: pair,
          interval: interval,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/indexPriceKlines", params: params, signed: false)
      end
      
      # Get mark price klines
      # @param symbol [String] Trading symbol
      # @param interval [String] Kline interval
      # @param limit [Integer] Number of candles (default: 500, max: 1500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Array>] Mark price klines
      def mark_price_klines(symbol:, interval:, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          interval: interval,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/markPriceKlines", params: params, signed: false)
      end
      
      # Get current average price
      # @param symbol [String] Trading symbol
      # @return [Hash] Average price
      def avg_price(symbol:)
        get("/fapi/v1/avgPrice", params: { symbol: symbol }, signed: false)
      end
      
      # Get premium index
      # @param symbol [String] Trading symbol (optional, all symbols if not provided)
      # @return [Hash, Array<Hash>] Premium index
      def premium_index(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        get("/fapi/v1/premiumIndex", params: params, signed: false)
      end
      
      # Get funding rate history
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Number of results (default: 100, max: 1000)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Hash>] Funding rate history
      def funding_rate_history(symbol:, limit: 100, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/fundingRate", params: params, signed: false)
      end
      
      # Get current funding rate
      # @param symbol [String] Trading symbol (optional)
      # @return [Hash, Array<Hash>] Current funding rate
      def funding_rate(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        get("/fapi/v1/premiumIndex", params: params, signed: false)
      end
      
      # Get open interest
      # @param symbol [String] Trading symbol
      # @return [Hash] Open interest
      def open_interest(symbol:)
        get("/fapi/v2/openInterest", params: { symbol: symbol }, signed: false)
      end
      
      # Get open interest statistics
      # @param symbol [String] Trading symbol
      # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
      # @param limit [Integer] Number of results (default: 30, max: 500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Hash>] Open interest statistics
      def open_interest_stats(symbol:, period:, limit: 30, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          period: period,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/futures/data/openInterestHist", params: params, signed: false)
      end
      
      # Get long/short ratio
      # @param symbol [String] Trading symbol
      # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
      # @param limit [Integer] Number of results (default: 30, max: 500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Hash>] Long/short ratio
      def long_short_ratio(symbol:, period:, limit: 30, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          period: period,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/futures/data/globalLongShortAccountRatio", params: params, signed: false)
      end
      
      # Get top trader long/short ratio
      # @param symbol [String] Trading symbol
      # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
      # @param limit [Integer] Number of results (default: 30, max: 500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Hash>] Top trader long/short ratio
      def top_long_short_ratio(symbol:, period:, limit: 30, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          period: period,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/futures/data/topLongShortAccountRatio", params: params, signed: false)
      end
      
      # Get taker long/short volume
      # @param symbol [String] Trading symbol
      # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
      # @param limit [Integer] Number of results (default: 30, max: 500)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Hash>] Taker long/short volume
      def taker_long_short_volume(symbol:, period:, limit: 30, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          period: period,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/futures/data/takerlongshortratio", params: params, signed: false)
      end
      
      # Get exchange info
      # @return [Hash] Exchange info including symbols, filters, etc.
      def exchange_info
        get("/fapi/v1/exchangeInfo", params: {}, signed: false)
      end
      
      # Get all instruments
      # @return [Array<Hash>] Instruments
      def instruments
        response = exchange_info
        response["symbols"] || []
      end
    end
  end
end
