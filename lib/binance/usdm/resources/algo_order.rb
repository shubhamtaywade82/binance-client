# frozen_string_literal: true

require_relative '../core/base_api'
require_relative '../models'

module Binance
  module USDM
    module Resources
      # Maps algo order option keywords to Binance API parameters.
      # `enum: true` values are uppercased (API expects ENUM strings).
      ALGO_ORDER_OPTIONS = {
        position_side: { param: :positionSide, enum: true },
        price: { param: :price },
        working_type: { param: :workingType, enum: true },
        time_in_force: { param: :timeInForce, enum: true },
        client_order_id: { param: :newClientOrderId },
        reduce_only: { param: :reduceOnly },
        close_position: { param: :closePosition },
        activation_price: { param: :activationPrice },
        callback_rate: { param: :callbackRate },
        price_protect: { param: :priceProtect },
        recv_window: { param: :recvWindow }
      }.freeze

      # Maps algo order query keywords to Binance API parameters.
      # `enum: true` values are uppercased (API expects ENUM strings).
      ALGO_QUERY_OPTIONS = {
        algo_type: { param: :algoType, enum: true },
        status: { param: :status, enum: true },
        start_time: { param: :startTime },
        end_time: { param: :endTime },
        page: { param: :page },
        limit: { param: :limit },
        recv_window: { param: :recvWindow }
      }.freeze

      # Algo Order resource for managing futures algorithmic orders.
      # Implements all Binance USDⓈ-M Futures algo order endpoints.
      class AlgoOrder < BaseAPI
        # Create a new algo order (STOP_LOSS/TAKE_PROFIT)
        # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
        # @param side [String] Order side: BUY or SELL
        # @param algo_type [String] Algo order type: STOP_LOSS, TAKE_PROFIT
        # @param quantity [String] Order quantity
        # @param stop_price [String] Stop price (trigger price)
        # @param position_side [String, nil] Position side: BOTH, LONG, SHORT (default: BOTH)
        # @param price [String, nil] Limit price (for limit orders)
        # @param working_type [String, nil] Working type: MARK_PRICE, CONTRACT_PRICE (default: CONTRACT_PRICE)
        # @param time_in_force [String, nil] Time in force: GTC, IOC, FOK (default: GTC)
        # @param client_order_id [String, nil] Client order ID
        # @param reduce_only [Boolean, nil] Reduce only order (default: false)
        # @param close_position [Boolean, nil] Close all open positions (default: false)
        # @param activation_price [String, nil] Activation price for trailing stop orders
        # @param callback_rate [String, nil] Callback rate for trailing stop orders (0.1 to 5.0)
        # @param price_protect [Boolean, nil] Price protect trigger condition (default: false)
        # @param recv_window [Integer, nil] Receive window in milliseconds
        # @return [Hash] Created algo order details
        def create(symbol:, side:, algo_type:, quantity:, stop_price:, **options)
          params = {
            symbol: symbol,
            side: side.to_s.upcase,
            algoType: algo_type.to_s.upcase,
            quantity: quantity,
            stopPrice: stop_price
          }
          options.each { |key, value| add_algo_option(params, key, value) }

          post('/fapi/v1/algoOrder', params: params)
        end

        # Cancel an algo order
        # @param symbol [String] Trading symbol
        # @param algo_id [Integer] Algo order ID
        # @param recv_window [Integer, nil] Receive window
        # @return [Hash] Canceled algo order details
        def cancel(symbol:, algo_id:, recv_window: nil)
          params = {
            symbol: symbol,
            algoId: algo_id
          }
          params[:recvWindow] = recv_window if recv_window

          delete('/fapi/v1/algoOrder', params: params)
        end

        # Get algo order details
        # @param symbol [String] Trading symbol
        # @param algo_id [Integer] Algo order ID
        # @param recv_window [Integer, nil] Receive window
        # @return [Hash] Algo order details
        def find(symbol:, algo_id:, recv_window: nil)
          params = {
            symbol: symbol,
            algoId: algo_id
          }
          params[:recvWindow] = recv_window if recv_window

          get('/fapi/v1/algoOrder', params: params)
        end

        # Get all open algo orders
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @param page [Integer, nil] Page number (default: 1)
        # @param limit [Integer, nil] Number of results (default: 10, max: 100)
        # @param recv_window [Integer, nil] Receive window
        # @return [Hash] Open algo orders with pagination
        def open(symbol: nil, page: nil, limit: nil, recv_window: nil)
          params = {}
          params[:symbol] = symbol if symbol
          params[:page] = page if page
          params[:limit] = limit if limit
          params[:recvWindow] = recv_window if recv_window

          get('/fapi/v1/algoOpenOrders', params: params)
        end

        # Get all algo orders (including historical)
        # @param symbol [String, nil] Trading symbol
        # @param algo_type [String, nil] Algo order type filter: STOP_LOSS, TAKE_PROFIT
        # @param status [String, nil] Status filter: WORKING, TRIGGERED, EXPIRED, CANCELED
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param page [Integer, nil] Page number (default: 1)
        # @param limit [Integer, nil] Number of results (default: 10, max: 100)
        # @param recv_window [Integer, nil] Receive window
        # @return [Hash] Algo orders with pagination
        def all(symbol: nil, **options)
          params = { symbol: symbol }.compact
          options.each { |key, value| add_algo_option(params, key, value, ALGO_QUERY_OPTIONS) }

          get('/fapi/v1/algoSubOrders', params: params)
        end

        # Cancel all open algo orders for a symbol
        # @param symbol [String] Trading symbol
        # @param recv_window [Integer, nil] Receive window
        # @return [Hash] Response
        def cancel_all(symbol:, recv_window: nil)
          params = {
            symbol: symbol
          }
          params[:recvWindow] = recv_window if recv_window

          delete('/fapi/v1/algoOpenOrders', params: params)
        end

        private

        def add_algo_option(params, key, value, table = ALGO_ORDER_OPTIONS)
          rule = table[key]
          raise ArgumentError, "Unknown algo order option: #{key}" unless rule
          return unless value

          params[rule[:param]] = rule[:enum] ? value.to_s.upcase : value
        end
      end
    end
  end
end
