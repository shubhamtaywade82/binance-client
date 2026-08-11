# frozen_string_literal: true

module BinanceUSDM
  module Enums
    # Order type enumeration
    module OrderType
      LIMIT = 'LIMIT'
      MARKET = 'MARKET'
      STOP = 'STOP'
      STOP_MARKET = 'STOP_MARKET'
      TAKE_PROFIT = 'TAKE_PROFIT'
      TAKE_PROFIT_MARKET = 'TAKE_PROFIT_MARKET'
      TRAILING_STOP_MARKET = 'TRAILING_STOP_MARKET'

      ALL = [LIMIT, MARKET, STOP, STOP_MARKET, TAKE_PROFIT, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET].freeze

      def self.valid?(type)
        ALL.include?(type.to_s.upcase)
      end

      def self.symbol?(type)
        [STOP_MARKET, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET].include?(type.to_s.upcase)
      end

      def self.limit?(type)
        type.to_s.upcase == LIMIT
      end

      def self.market?(type)
        type.to_s.upcase == MARKET
      end

      def self.stop?(type)
        [STOP, STOP_MARKET].include?(type.to_s.upcase)
      end
    end
  end
end
