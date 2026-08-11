# frozen_string_literal: true

require_relative '../core/base_api'
require_relative '../models'

module BinanceUSDM
  module Resources
    # Class-level (ActiveRecord-style) accessors for the account resource.
    module AccountClassMethods
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

      # Get account information (class method)
      # @example BinanceUSDM::Resources::Account.info
      def info
        client.account.info
      end

      # Get account balances (class method)
      # @example BinanceUSDM::Resources::Account.balance
      def balance
        client.account.balance
      end

      # Get positions (class method)
      # @example BinanceUSDM::Resources::Account.positions(symbol: "ETHUSDT")
      def positions(symbol: nil)
        client.account.positions(symbol: symbol)
      end

      # Change position mode (class method)
      # @example BinanceUSDM::Resources::Account.change_position_mode(dual_side_position: true)
      def change_position_mode(dual_side_position:)
        client.account.change_position_mode(dual_side_position: dual_side_position)
      end

      # Get current position mode (class method)
      # @example BinanceUSDM::Resources::Account.position_mode
      def position_mode
        client.account.position_mode
      end

      # Change initial leverage (class method)
      # @example BinanceUSDM::Resources::Account.change_leverage(symbol: "ETHUSDT", leverage: 10)
      def change_leverage(symbol:, leverage:)
        client.account.change_leverage(symbol: symbol, leverage: leverage)
      end

      # Change user's margin mode (class method)
      # @example BinanceUSDM::Resources::Account.change_margin_mode(symbol: "ETHUSDT", margin_mode: "ISOLATED")
      def change_margin_mode(symbol:, margin_mode:)
        client.account.change_margin_mode(symbol: symbol, margin_mode: margin_mode)
      end

      # Modify isolated position margin (class method)
      # @example BinanceUSDM::Resources::Account.modify_position_margin(symbol: "ETHUSDT", amount: "100", type: 1)
      def modify_position_margin(symbol:, amount:, type:, position_side: 'BOTH')
        client.account.modify_position_margin(symbol: symbol, amount: amount, type: type,
                                              position_side: position_side)
      end

      # Get position margin change history (class method)
      # @example BinanceUSDM::Resources::Account.position_margin_history(symbol: "ETHUSDT")
      def position_margin_history(symbol:, type: nil, start_time: nil, end_time: nil, limit: 500)
        client.account.position_margin_history(symbol: symbol, type: type, start_time: start_time,
                                               end_time: end_time, limit: limit)
      end

      # Get income history (class method)
      # @example BinanceUSDM::Resources::Account.income_history(symbol: "ETHUSDT", income_type: "COMMISSION")
      def income_history(symbol: nil, income_type: nil, start_time: nil, end_time: nil, limit: 500)
        client.account.income_history(symbol: symbol, income_type: income_type, start_time: start_time,
                                      end_time: end_time, limit: limit)
      end

      # Get commission rates (class method)
      # @example BinanceUSDM::Resources::Account.commission_rate(symbol: "ETHUSDT")
      def commission_rate(symbol:)
        client.account.commission_rate(symbol: symbol)
      end
    end

    # Account resource for managing account information and balances.
    # Supports both instance methods (via client) and class methods (via default_client).
    class Account < BaseAPI
      extend AccountClassMethods

      # Get account information
      # @return [Models::Account] Account details
      def info
        response = get('/fapi/v2/account', params: {})
        Models::Account.new(response)
      end

      # Get account balance
      # @return [Array<Models::Balance>] Account balances
      def balance
        response = get('/fapi/v2/balance', params: {})
        response.map { |balance_data| Models::Balance.new(balance_data) }
      end

      # Get positions
      # @param symbol [String] Trading symbol (optional, all symbols if not provided)
      # @return [Array<Models::Position>] Positions
      def positions(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol

        response = get('/fapi/v2/positionRisk', params: params)
        response.map { |position_data| Models::Position.new(position_data) }
      end

      # Change position mode (One-way or Hedge Mode)
      # @param dual_side_position [Boolean] true for Hedge Mode, false for One-way Mode
      # @return [Hash] Response
      def change_position_mode(dual_side_position:)
        post('/fapi/v1/positionSide/dual', params: { dualSidePosition: dual_side_position ? 'true' : 'false' })
      end

      # Get current position mode
      # @return [Hash] Position mode status
      def position_mode
        get('/fapi/v1/positionSide/dual')
      end

      # Change initial leverage
      # @param symbol [String] Trading symbol
      # @param leverage [Integer] Target leverage (1-125)
      # @return [Hash] Response with new leverage and max notional value
      def change_leverage(symbol:, leverage:)
        post('/fapi/v1/leverage', params: { symbol: symbol, leverage: leverage })
      end

      # Change user's margin mode
      # @param symbol [String] Trading symbol
      # @param margin_mode [String] ISOLATED or CROSSED
      # @return [Hash] Response
      def change_margin_mode(symbol:, margin_mode:)
        post('/fapi/v1/marginType', params: { symbol: symbol, marginType: margin_mode })
      end

      # Modify isolated position margin
      # @param symbol [String] Trading symbol
      # @param amount [String] Amount to add/remove
      # @param type [Integer] 1: add margin, 2: reduce margin
      # @param position_side [String] BOTH, LONG, SHORT (default: BOTH)
      # @return [Hash] Response
      def modify_position_margin(symbol:, amount:, type:, position_side: 'BOTH')
        post('/fapi/v1/positionMargin', params: {
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

        get('/fapi/v1/positionMargin/history', params: params)
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

        get('/fapi/v1/income', params: params)
      end

      # Get commission rates
      # @param symbol [String] Trading symbol
      # @return [Hash] Commission rates
      def commission_rate(symbol:)
        get('/fapi/v1/commissionRate', params: { symbol: symbol })
      end

      # Get leverage brackets
      # @param symbol [String, nil] Trading symbol (optional)
      # @return [Array, Hash] Leverage bracket information
      def leverage_brackets(symbol: nil)
        params = symbol ? { symbol: symbol } : {}
        get('/fapi/v1/leverageBracket', params: params)
      end

      # Create listenKey for user data stream
      # @return [Hash] Hash containing listenKey
      def create_listen_key
        post('/fapi/v1/listenKey', signed: false)
      end

      # Keep-alive listenKey
      # @param listen_key [String, nil] Listen key
      # @return [Hash] Response
      def keep_alive_listen_key(listen_key = nil)
        params = listen_key ? { listenKey: listen_key } : {}
        put('/fapi/v1/listenKey', params: params, signed: false)
      end

      # Close listenKey
      # @param listen_key [String, nil] Listen key
      # @return [Hash] Response
      def close_listen_key(listen_key = nil)
        params = listen_key ? { listenKey: listen_key } : {}
        delete('/fapi/v1/listenKey', params: params, signed: false)
      end
    end
  end
end
