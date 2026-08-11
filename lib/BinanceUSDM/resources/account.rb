# frozen_string_literal: true

require_relative "../core/base_api"
require_relative "../models"

module BinanceUSDM
  module Resources
    # Account resource for managing account information and balances.
    class Account < BaseAPI
      # Get account information
      # @return [Models::Account] Account details
      def info
        response = get("/fapi/v2/account", params: {})
        Models::Account.new(response)
      end
      
      # Get account balance
      # @return [Array<Models::Balance>] Account balances
      def balance
        response = get("/fapi/v2/balance", params: {})
        response.map { |balance_data| Models::Balance.new(balance_data) }
      end
      
      # Get positions
      # @param symbol [String] Trading symbol (optional, all symbols if not provided)
      # @return [Array<Models::Position>] Positions
      def positions(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        response = get("/fapi/v2/positionRisk", params: params)
        response.map { |position_data| Models::Position.new(position_data) }
      end
      
      # Change position mode (One-way or Hedge Mode)
      # @param dual_side_position [Boolean] true for Hedge Mode, false for One-way Mode
      # @return [Hash] Response
      def change_position_mode(dual_side_position:)
        post("/fapi/v1/positionSide/dual", params: { dualSidePosition: dual_side_position ? "true" : "false" })
      end
      
      # Get current position mode
      # @return [Hash] Position mode status
      def position_mode
        get("/fapi/v1/positionSide/dual")
      end
      
      # Change initial leverage
      # @param symbol [String] Trading symbol
      # @param leverage [Integer] Target leverage (1-125)
      # @return [Hash] Response with new leverage and max notional value
      def change_leverage(symbol:, leverage:)
        post("/fapi/v1/leverage", params: { symbol: symbol, leverage: leverage })
      end
      
      # Change user's margin mode
      # @param symbol [String] Trading symbol
      # @param margin_mode [String] ISOLATED or CROSSED
      # @return [Hash] Response
      def change_margin_mode(symbol:, margin_mode:)
        post("/fapi/v1/marginType", params: { symbol: symbol, marginType: margin_mode })
      end
      
      # Modify isolated position margin
      # @param symbol [String] Trading symbol
      # @param amount [String] Amount to add/remove
      # @param type [Integer] 1: add margin, 2: reduce margin
      # @param position_side [String] BOTH, LONG, SHORT (default: BOTH)
      # @return [Hash] Response
      def modify_position_margin(symbol:, amount:, type:, position_side: "BOTH")
        post("/fapi/v1/positionMargin", params: {
          symbol: symbol,
          amount: amount,
          type: type,
          positionSide: position_side
        })
      end
      
      # Get position margin change history
      # @param symbol [String] Trading symbol
      # @param type [Integer] 1: add margin, 2: reduce margin (optional)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @param limit [Integer] Number of records (default: 500)
      # @return [Array<Hash>] Margin change history
      def position_margin_history(symbol:, type: nil, start_time: nil, end_time: nil, limit: 500)
        params = {
          symbol: symbol,
          limit: limit
        }
        
        params[:type] = type if type
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/positionMargin/history", params: params)
      end
      
      # Get income history
      # @param symbol [String] Trading symbol (optional)
      # @param income_type [String] Income type: TRANSFER, COMMISSION, INSURANCE, etc. (optional)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @param limit [Integer] Number of records (default: 500, max: 1000)
      # @return [Array<Hash>] Income history
      def income_history(symbol: nil, income_type: nil, start_time: nil, end_time: nil, limit: 500)
        params = { limit: limit }
        
        params[:symbol] = symbol if symbol
        params[:incomeType] = income_type if income_type
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        get("/fapi/v1/income", params: params)
      end
      
      # Get commission rates
      # @param symbol [String] Trading symbol
      # @return [Hash] Commission rates
      def commission_rate(symbol:)
        get("/fapi/v1/commissionRate", params: { symbol: symbol })
      end
    end
  end
end
