# frozen_string_literal: true

require 'bigdecimal'

module BinanceUSDM
  module WebSocket
    # Maintains a real-time synchronized Level-2 order book using depth streams.
    class OrderBook
      attr_reader :symbol, :bids, :asks, :last_update_id, :synced

      # Initialize local order book
      # @param symbol [String] Trading symbol (e.g. "BTCUSDT")
      # @param client [BinanceUSDM::Client, BinanceUSDM::API] REST client for snapshot fetching
      def initialize(symbol:, client: nil)
        @symbol = symbol.to_s.upcase
        @client = client
        @bids = {}
        @asks = {}
        @last_update_id = nil
        @synced = false
        @event_buffer = []
      end

      # Check if book is fully synchronized with exchange sequence
      def synced?
        @synced
      end

      # Best bid price
      # @return [BigDecimal, nil]
      def best_bid
        @bids.keys.max
      end

      # Best ask price
      # @return [BigDecimal, nil]
      def best_ask
        @asks.keys.min
      end

      # Bid-ask spread
      # @return [BigDecimal, nil]
      def spread
        return nil unless best_bid && best_ask

        best_ask - best_bid
      end

      # Mid price
      # @return [BigDecimal, nil]
      def mid_price
        return nil unless best_bid && best_ask

        (best_bid + best_ask) / 2
      end

      # Process incoming depthUpdate event from WebSocket
      # @param event [Hash] depthUpdate event payload
      def process_event(event)
        unless @synced
          @event_buffer << event
          return
        end

        # Continuity check: previous update ID must match pu
        if event['pu'] && event['pu'] != @last_update_id
          resync
          return
        end

        apply_price_levels(event['b'], @bids)
        apply_price_levels(event['a'], @asks)
        @last_update_id = event['u']
      end

      # Apply REST depth snapshot to initialize order book
      # @param snapshot [Hash] Snapshot response containing lastUpdateId, bids, asks
      def apply_snapshot(snapshot)
        @bids.clear
        @asks.clear
        @last_update_id = snapshot['lastUpdateId']

        apply_price_levels(snapshot['bids'], @bids)
        apply_price_levels(snapshot['asks'], @asks)

        replay_buffer
        @synced = true
      end

      # Reset book and request fresh snapshot
      def resync
        @synced = false
        @bids.clear
        @asks.clear
        @event_buffer.clear
        fetch_snapshot if @client
      end

      # Fetch snapshot via REST client
      def fetch_snapshot
        return unless @client

        snapshot = @client.market.depth(symbol: symbol, limit: 1000)
        apply_snapshot(snapshot)
      end

      private

      # Replay buffered events received while waiting for snapshot
      def replay_buffer
        @event_buffer.each do |event|
          next if event['u'] < @last_update_id

          if @last_update_id.between?(event['U'], event['u'])
            apply_price_levels(event['b'], @bids)
            apply_price_levels(event['a'], @asks)
            @last_update_id = event['u']
          elsif event['pu'] == @last_update_id
            apply_price_levels(event['b'], @bids)
            apply_price_levels(event['a'], @asks)
            @last_update_id = event['u']
          end
        end
        @event_buffer.clear
      end

      # Update price levels (quantity 0 removes price level)
      def apply_price_levels(levels, book_side)
        return unless levels

        levels.each do |price_str, qty_str|
          price = BigDecimal(price_str.to_s)
          qty = BigDecimal(qty_str.to_s)

          if qty.zero?
            book_side.delete(price)
          else
            book_side[price] = qty
          end
        end
      end
    end
  end
end
