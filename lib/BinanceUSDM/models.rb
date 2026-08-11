# frozen_string_literal: true

require_relative 'core/base_model'

module BinanceUSDM
  module Models
    # Order model representing a futures order.
    class Order < BaseModel
      # @!attribute [r] order_id
      #   @return [Integer] Order ID
      # @!attribute [r] symbol
      #   @return [String] Trading symbol
      # @!attribute [r] status
      #   @return [String] Order status (NEW, PARTIALLY_FILLED, FILLED, CANCELED, REJECTED, EXPIRED)
      # @!attribute [r] client_order_id
      #   @return [String] Client order ID
      # @!attribute [r] price
      #   @return [String] Order price
      # @!attribute [r] avg_price
      #   @return [String] Average fill price
      # @!attribute [r] orig_qty
      #   @return [String] Original quantity
      # @!attribute [r] executed_qty
      #   @return [String] Executed quantity
      # @!attribute [r] cum_qty
      #   @return [String] Cumulative filled quantity
      # @!attribute [r] cum_quote
      #   @return [String] Cumulative quote asset filled
      # @!attribute [r] side
      #   @return [String] Order side (BUY/SELL)
      # @!attribute [r] type
      #   @return [String] Order type
      # @!attribute [r] time_in_force
      #   @return [String] Time in force
      # @!attribute [r] update_time
      #   @return [Integer] Last update time
      # @!attribute [r] time
      #   @return [Integer] Order creation time

      def status?
        %w[FILLED].include?(status)
      end

      def partially_filled?
        %w[PARTIALLY_FILLED].include?(status)
      end

      def canceled?
        %w[CANCELED REJECTED EXPIRED].include?(status)
      end

      def active?
        %w[NEW PARTIALLY_FILLED].include?(status)
      end

      def filled?
        status == 'FILLED'
      end
    end

    # Position model representing a futures position.
    class Position < BaseModel
      def leverage
        @leverage&.to_i
      end

      def long?
        position_side == 'LONG' || (position_side == 'BOTH' && position_amt.to_f.positive?)
      end

      def short?
        position_side == 'SHORT' || (position_side == 'BOTH' && position_amt.to_f.negative?)
      end

      def position?
        position_amt.to_f != 0
      end

      def profit?
        unrealized_profit.to_f.positive?
      end
    end

    # Account model representing account information.
    class Account < BaseModel
      def total_unrealized_pnl
        @total_unrealized_pnl || @total_unrealized_profit || @totalUnrealizedProfit
      end

      def equity
        (total_wallet_balance.to_f + total_unrealized_pnl.to_f).to_s
      end

      def margin_ratio
        return '0' if total_margin_balance.to_f.zero?

        ((total_position_initial_margin.to_f / total_margin_balance) * 100).round(2).to_s
      end
    end

    # Trade model representing a filled trade.
    class Trade < BaseModel
      # @!attribute [r] id
      #   @return [Integer] Trade ID
      # @!attribute [r] order_id
      #   @return [Integer] Order ID
      # @!attribute [r] symbol
      #   @return [String] Trading symbol
      # @!attribute [r] price
      #   @return [String] Trade price
      # @!attribute [r] qty
      #   @return [String] Trade quantity
      # @!attribute [r] quote_qty
      #   @return [String] Quote quantity
      # @!attribute [r] commission
      #   @return [String] Commission
      # @!attribute [r] commission_asset
      #   @return [String] Commission asset
      # @!attribute [r] time
      #   @return [Integer] Trade time
      # @!attribute [r] buyer
      #   @return [Boolean] Is buyer
      # @!attribute [r] maker
      #   @return [Boolean] Is maker
    end

    # Ticker model representing 24hr ticker statistics.
    class Ticker < BaseModel
      # @!attribute [r] symbol
      #   @return [String] Trading symbol
      # @!attribute [r] last_price
      #   @return [String] Last price
      # @!attribute [r] price_change
      #   @return [String] Price change
      # @!attribute [r] price_change_percent
      #   @return [String] Price change percent
      # @!attribute [r] high_price
      #   @return [String] 24h high price
      # @!attribute [r] low_price
      #   @return [String] 24h low price
      # @!attribute [r] volume
      #   @return [String] 24h volume
      # @!attribute [r] quote_volume
      #   @return [String] 24h quote volume
      # @!attribute [r] open_price
      #   @return [String] Open price
      # @!attribute [r] count
      #   @return [Integer] Trade count
    end

    # Balance model representing asset balance.
    class Balance < BaseModel
      # @!attribute [r] asset
      #   @return [String] Asset code
      # @!attribute [r] wallet_balance
      #   @return [String] Wallet balance
      # @!attribute [r] unrealized_profit
      #   @return [String] Unrealized PnL
      # @!attribute [r] available_balance
      #   @return [String] Available balance
      # @!attribute [r] max_withdraw_amount
      #   @return [String] Max withdraw amount
    end
  end
end
