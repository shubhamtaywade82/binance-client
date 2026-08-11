# frozen_string_literal: true

require_relative '../core/base_model'

module Binance
  module Spot
    module Models
      # Order model representing a spot order.
      class Order < Core::BaseModel
        def active?
          %w[NEW PARTIALLY_FILLED].include?(status)
        end

        def filled?
          status == 'FILLED'
        end

        def canceled?
          %w[CANCELED REJECTED EXPIRED].include?(status)
        end
      end

      # Trade model representing a filled spot trade.
      class Trade < Core::BaseModel; end

      # Ticker model representing 24hr ticker statistics.
      class Ticker < Core::BaseModel; end

      # Account model representing spot account information and balances.
      class Account < Core::BaseModel; end
    end
  end
end
