# frozen_string_literal: true

require_relative 'base_client'
require 'securerandom'

module Binance
  module USDM
    module WebSocket
      # Market data WebSocket client for real-time market updates.
      class MarketClient < BaseClient
        EVENT_HANDLERS = {
          '24hrTicker' => :on_ticker,
          'trade' => :on_trade,
          'kline' => :on_kline,
          'forceOrder' => :on_liquidation,
          'markPriceUpdate' => :on_mark_price,
          'depthUpdate' => :on_depth
        }.freeze

        attr_accessor :on_ticker, :on_trade, :on_orderbook, :on_kline,
                      :on_liquidation, :on_mark_price, :on_depth

        # Subscribe to ticker stream
        # @param symbols [Array<String>] Trading symbols (e.g., ["BTCUSDT"])
        def subscribe_ticker(*symbols)
          streams = symbols.map { |s| "#{s.downcase}@ticker" }
          subscribe(streams)
        end

        # Subscribe to trade stream
        # @param symbols [Array<String>] Trading symbols
        def subscribe_trade(*symbols)
          streams = symbols.map { |s| "#{s.downcase}@trade" }
          subscribe(streams)
        end

        # Subscribe to order book depth
        # @param symbols [Array<String>] Trading symbols
        # @param level [Integer] Depth level: 5, 10, 20 (default: 20)
        def subscribe_orderbook(*symbols, level: 20)
          streams = symbols.map { |s| "#{s.downcase}@depth#{level}" }
          subscribe(streams)
        end

        # Subscribe to kline/candlestick stream
        # @param symbols [Array<String>] Trading symbols
        # @param interval [String] Kline interval (default: "1m")
        def subscribe_kline(*symbols, interval: '1m')
          streams = symbols.map { |s| "#{s.downcase}@kline_#{interval}" }
          subscribe(streams)
        end

        # Subscribe to liquidation stream
        # @param symbols [Array<String>] Trading symbols (use "!" for all symbols)
        def subscribe_liquidation(*symbols)
          syms = symbols.empty? ? ['!'] : symbols
          streams = syms.map { |s| "#{s.downcase}@forceOrder" }
          subscribe(streams)
        end

        # Subscribe to mark price stream
        # @param symbols [Array<String>] Trading symbols
        # @param fast [Boolean] Use fast update (1 second) instead of 3 seconds
        def subscribe_mark_price(*symbols, fast: false)
          suffix = fast ? '@markPrice@1s' : '@markPrice'
          streams = symbols.map { |s| "#{s.downcase}#{suffix}" }
          subscribe(streams)
        end

        # Subscribe to mini ticker stream
        # @param symbols [Array<String>] Trading symbols
        def subscribe_mini_ticker(*symbols)
          if symbols.empty?
            subscribe(['!miniTicker@arr'])
          else
            streams = symbols.map { |s| "#{s.downcase}@miniTicker" }
            subscribe(streams)
          end
        end

        # Subscribe to book ticker (best bid/ask)
        # @param symbols [Array<String>] Trading symbols
        def subscribe_book_ticker(*symbols)
          if symbols.empty?
            subscribe(['!bookTicker'])
          else
            streams = symbols.map { |s| "#{s.downcase}@bookTicker" }
            subscribe(streams)
          end
        end

        # Subscribe to continuous contract klines
        # @param pair [String] Pair (e.g., "BTCUSDT")
        # @param contract_type [String] Contract type: PERPETUAL, CURRENT_QUARTER, NEXT_QUARTER
        # @param interval [String] Kline interval
        def subscribe_continuous_kline(pair:, contract_type: 'PERPETUAL', interval: '1m')
          stream = "#{pair.downcase}_#{contract_type.downcase}@continuousKline_#{interval}"
          subscribe([stream])
        end

        # Subscribe to index price klines
        # @param pair [String] Pair (e.g., "BTCUSDT")
        # @param interval [String] Kline interval
        def subscribe_index_price_kline(pair:, interval: '1m')
          stream = "#{pair.downcase}@indexPriceKline_#{interval}"
          subscribe([stream])
        end

        # Subscribe to mark price klines
        # @param symbol [String] Trading symbol
        # @param interval [String] Kline interval
        def subscribe_mark_price_kline(symbol:, interval: '1m')
          stream = "#{symbol.downcase}@markPriceKline_#{interval}"
          subscribe([stream])
        end

        # Subscribe to open interest
        # @param symbols [Array<String>] Trading symbols
        # @param period [String] Period: 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d
        def subscribe_open_interest(*symbols, period: '5m')
          streams = symbols.map { |s| "#{s.downcase}@openInterest_#{period}" }
          subscribe(streams)
        end

        private

        # Handle incoming messages
        # @param data [Hash] Message data
        def on_message(data)
          return handle_subscription_response(data) if data.key?('result') || data.key?('id')

          dispatch_stream(data['data'] || data, data)
        end

        # Handle subscription confirmation responses
        def handle_subscription_response(data)
          logger.debug("Subscription response: #{data.inspect}")
        end

        # Route stream data to the registered callback
        def dispatch_stream(stream_data, original)
          handler = stream_handler(stream_data)
          if handler
            public_send(handler)&.call(stream_data)
          else
            logger.debug("Unknown message type: #{original.inspect}")
          end
        end

        # Resolve callback accessor for a stream message
        def stream_handler(stream_data)
          return :on_orderbook if stream_data.key?('bids') && stream_data.key?('asks')

          EVENT_HANDLERS[stream_data['e']]
        end
      end
    end
  end
end
