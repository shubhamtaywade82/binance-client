# frozen_string_literal: true

require_relative 'base'
require_relative '../models'

module Binance
  module Spot
    module Resources
      # Spot account information, balances, trade history, and rate limits.
      class Account < Base
        # Get account information and balances
        def info
          Models::Account.new(@api.request(:get_api_v3_account))
        end

        # Get this account's current spot trading commission rates
        def commission(symbol:)
          @api.request(:get_api_v3_account_commission, symbol: symbol)
        end

        # Get account trade list (fills)
        def trades(symbol:, order_id: nil, start_time: nil, end_time: nil, from_id: nil, limit: 500)
          params = { symbol: symbol, limit: limit }
          params[:orderId] = order_id if order_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time
          params[:fromId] = from_id if from_id

          response = @api.request(:get_api_v3_mytrades, params)
          response.map { |trade_data| Models::Trade.new(trade_data) }
        end

        # Get allocations resulting from SOR order placement
        def allocations(symbol:, start_time: nil, end_time: nil, from_id: nil, limit: 500)
          params = { symbol: symbol, limit: limit }
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time
          params[:fromId] = from_id if from_id

          @api.request(:get_api_v3_myallocations, params)
        end

        # Get order filters that would apply to this account for a symbol
        def filters(symbol:)
          @api.request(:get_api_v3_myfilters, symbol: symbol)
        end

        # Get trades this account's orders prevented via self-trade prevention
        def prevented_matches(symbol:, prevented_match_id: nil, order_id: nil, from_prevented_match_id: nil,
                              limit: 500)
          params = { symbol: symbol, limit: limit }
          params[:preventedMatchId] = prevented_match_id if prevented_match_id
          params[:orderId] = order_id if order_id
          params[:fromPreventedMatchId] = from_prevented_match_id if from_prevented_match_id

          @api.request(:get_api_v3_mypreventedmatches, params)
        end
      end
    end
  end
end
