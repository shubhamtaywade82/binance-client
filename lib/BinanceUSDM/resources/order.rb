# frozen_string_literal: true

require_relative '../core/base_api'
require_relative '../models'

module BinanceUSDM
  module Resources
    # Order resource for managing futures orders.
    # Implements all Binance USDⓈ-M Futures order endpoints.
    # Supports both instance methods (via client) and class methods (via default_client).
    class Order < BaseAPI
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

        # Place a new order (class method)
        # @example BinanceUSDM::Resources::Order.create(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
        def create(symbol:, side:, type:, **kwargs)
          client.order.place(symbol: symbol, side: side, type: type, **kwargs)
        end

        # Find an order by ID or client_order_id
        # @example BinanceUSDM::Resources::Order.find(symbol: "ETHUSDT", order_id: 123456)
        def find(symbol:, order_id: nil, client_order_id: nil, **kwargs)
          client.order.find(symbol: symbol, order_id: order_id, client_order_id: client_order_id, **kwargs)
        end

        # Get open orders
        # @example BinanceUSDM::Resources::Order.open(symbol: "ETHUSDT")
        def open(symbol: nil, **_kwargs)
          symbol ? client.order.open_orders(symbol: symbol) : client.order.all_open_orders
        end

        # Cancel an order
        # @example BinanceUSDM::Resources::Order.cancel(symbol: "ETHUSDT", order_id: 123456)
        def cancel(symbol:, order_id: nil, client_order_id: nil, **kwargs)
          client.order.cancel(symbol: symbol, order_id: order_id, client_order_id: client_order_id, **kwargs)
        end

        # Cancel all orders for a symbol
        # @example BinanceUSDM::Resources::Order.cancel_all(symbol: "ETHUSDT")
        def cancel_all(symbol:, **kwargs)
          client.order.cancel_all(symbol: symbol, **kwargs)
        end

        # Batch create orders
        # @example BinanceUSDM::Resources::Order.batch_create([{symbol: "ETHUSDT", ...}, {symbol: "BTCUSDT", ...}])
        def batch_create(orders_array, **kwargs)
          client.order.batch_place(orders: orders_array, **kwargs)
        end

        # Batch cancel orders
        # @example BinanceUSDM::Resources::Order.batch_cancel(symbol: "ETHUSDT", order_ids: [123, 456])
        def batch_cancel(symbol:, order_ids: nil, client_order_ids: nil, **kwargs)
          client.order.batch_cancel(symbol: symbol, order_ids: order_ids, client_order_ids: client_order_ids, **kwargs)
        end
      end
      # Place a new order (FULL parameter support)
      # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
      # @param side [String] Order side: BUY or SELL
      # @param type [String] Order type: LIMIT, MARKET, STOP, STOP_MARKET, TAKE_PROFIT, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET
      # @param quantity [String, nil] Order quantity (not required for closePosition orders)
      # @param price [String, nil] Limit price (required for LIMIT orders)
      # @param position_side [String, nil] Position side: BOTH, LONG, SHORT (default: BOTH for One-way Mode; required for Hedge Mode)
      # @param time_in_force [String, nil] Time in force: GTC, IOC, FOK (default: GTC for LIMIT; not applicable to MARKET/STOP_MARKET/TAKE_PROFIT_MARKET/TRAILING_STOP_MARKET)
      # @param reduce_only [Boolean, nil] Reduce only order (default: false)
      # @param close_position [Boolean, nil] Close all open positions (default: false)
      # @param client_order_id [String, nil] Client order ID (max length 36, auto-generated if not provided)
      # @param response_type [String, nil] New order response type: ACK, RESULT, FULL (default: RESULT)
      # @param stop_price [String, nil] Stop price (for STOP, STOP_MARKET, TAKE_PROFIT, TAKE_PROFIT_MARKET orders)
      # @param activation_price [String, nil] Activation price for trailing stop orders
      # @param callback_rate [String, nil] Callback rate for trailing stop orders (0.1 to 5.0)
      # @param working_type [String, nil] Working type: MARK_PRICE, CONTRACT_PRICE (default: CONTRACT_PRICE)
      # @param price_protect [Boolean, nil] Price protect trigger condition (default: false)
      # @param price_match [String, nil] Price match mode: NONE, OPPONENT, OPPONENT_PROACTIVE, QUEUE, QUEUE_PROACTIVE
      # @param self_trade_prevention_mode [String, nil] STP mode: NONE, EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH
      # @param good_till_date [Integer, nil] Good till date timestamp (for GTD orders)
      # @param new_client_order_id [String, nil] Alternative parameter for client_order_id
      # @param recv_window [Integer, nil] Receive window in milliseconds
      # @return [Models::Order] Created order
      def place(symbol:, side:, type:, quantity: nil, price: nil, position_side: nil,
                time_in_force: nil, reduce_only: nil, close_position: nil, client_order_id: nil,
                response_type: nil, stop_price: nil, activation_price: nil, callback_rate: nil,
                working_type: nil, price_protect: nil, price_match: nil,
                self_trade_prevention_mode: nil, good_till_date: nil, new_client_order_id: nil,
                recv_window: nil)
        params = {
          symbol: symbol,
          side: side.to_s.upcase,
          type: type.to_s.upcase
        }

        params[:quantity] = quantity if quantity
        params[:price] = price if price
        params[:positionSide] = position_side.to_s.upcase if position_side
        params[:timeInForce] = time_in_force.to_s.upcase if time_in_force
        params[:reduceOnly] = reduce_only if reduce_only == true
        params[:closePosition] = close_position if close_position == true
        params[:newClientOrderId] = client_order_id || new_client_order_id if client_order_id || new_client_order_id
        params[:newOrderRespType] = response_type.to_s.upcase if response_type
        params[:stopPrice] = stop_price if stop_price
        params[:activationPrice] = activation_price if activation_price
        params[:callbackRate] = callback_rate if callback_rate
        params[:workingType] = working_type.to_s.upcase if working_type
        params[:priceProtect] = price_protect if price_protect == true
        params[:priceMatch] = price_match.to_s.upcase if price_match
        params[:selfTradePreventionMode] = self_trade_prevention_mode.to_s.upcase if self_trade_prevention_mode
        params[:goodTillDate] = good_till_date if good_till_date
        params[:recvWindow] = recv_window if recv_window

        response = post('/fapi/v1/order', params: params)
        Models::Order.new(response)
      end

      # Test order creation (signature checked but order not sent to matching engine)
      # @param symbol [String] Trading symbol
      # @param side [String] Order side: BUY or SELL
      # @param type [String] Order type
      # @param quantity [String, nil] Order quantity
      # @param price [String, nil] Limit price
      # @param position_side [String, nil] Position side
      # @param time_in_force [String, nil] Time in force
      # @param reduce_only [Boolean, nil] Reduce only order
      # @param close_position [Boolean, nil] Close all open positions
      # @param client_order_id [String, nil] Client order ID
      # @param response_type [String, nil] Response type
      # @param stop_price [String, nil] Stop price
      # @param activation_price [String, nil] Activation price
      # @param callback_rate [String, nil] Callback rate
      # @param working_type [String, nil] Working type
      # @param price_protect [Boolean, nil] Price protect
      # @param recv_window [Integer, nil] Receive window
      # @return [Hash] Empty response if successful
      def test(symbol:, side:, type:, quantity: nil, price: nil, position_side: nil,
               time_in_force: nil, reduce_only: nil, close_position: nil, client_order_id: nil,
               response_type: nil, stop_price: nil, activation_price: nil, callback_rate: nil,
               working_type: nil, price_protect: nil, recv_window: nil)
        params = {
          symbol: symbol,
          side: side.to_s.upcase,
          type: type.to_s.upcase
        }

        params[:quantity] = quantity if quantity
        params[:price] = price if price
        params[:positionSide] = position_side.to_s.upcase if position_side
        params[:timeInForce] = time_in_force.to_s.upcase if time_in_force
        params[:reduceOnly] = reduce_only if reduce_only == true
        params[:closePosition] = close_position if close_position == true
        params[:newClientOrderId] = client_order_id if client_order_id
        params[:newOrderRespType] = response_type.to_s.upcase if response_type
        params[:stopPrice] = stop_price if stop_price
        params[:activationPrice] = activation_price if activation_price
        params[:callbackRate] = callback_rate if callback_rate
        params[:workingType] = working_type.to_s.upcase if working_type
        params[:priceProtect] = price_protect if price_protect == true
        params[:recvWindow] = recv_window if recv_window

        post('/fapi/v1/order/test', params: params)
      end

      # Modify an existing order
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID
      # @param client_order_id [String, nil] Client order ID (origClientOrderId)
      # @param orig_client_order_id [String, nil] Alias for client_order_id
      # @param side [String, nil] Order side
      # @param quantity [String, nil] New quantity
      # @param price [String, nil] New price
      # @param client_order_id_new [String, nil] New client order ID for the modified order
      # @param recv_window [Integer, nil] Receive window
      # @return [Models::Order] Modified order
      def modify(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, side: nil,
                 quantity: nil, price: nil, client_order_id_new: nil, recv_window: nil)
        client_oid = orig_client_order_id || client_order_id
        raise ArgumentError, 'Either order_id or client_order_id must be provided' unless order_id || client_oid

        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_oid if client_oid
        params[:side] = side.to_s.upcase if side
        params[:quantity] = quantity if quantity
        params[:price] = price if price
        params[:newClientOrderId] = client_order_id_new if client_order_id_new
        params[:recvWindow] = recv_window if recv_window

        response = put('/fapi/v1/order', params: params)
        Models::Order.new(response)
      end

      # Get order modification history
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID
      # @param client_order_id [String, nil] Client order ID
      # @param start_time [Integer, nil] Start time in ms
      # @param end_time [Integer, nil] End time in ms
      # @param limit [Integer] Number of results (default: 500, max: 1000)
      # @return [Array<Hash>] Order modification history
      def modify_history(symbol:, order_id: nil, client_order_id: nil, start_time: nil, end_time: nil, limit: 500)
        params = {
          symbol: symbol,
          limit: limit
        }

        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_order_id if client_order_id
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time

        get('/fapi/v1/orderModifyHistory', params: params)
      end

      # Cancel an active order
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID
      # @param client_order_id [String, nil] Client order ID
      # @param orig_client_order_id [String, nil] Alias for client_order_id
      # @param recv_window [Integer, nil] Receive window
      # @return [Models::Order] Canceled order
      def cancel(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, recv_window: nil)
        client_oid = orig_client_order_id || client_order_id
        raise ArgumentError, 'Either order_id or client_order_id must be provided' unless order_id || client_oid

        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_oid if client_oid
        params[:recvWindow] = recv_window if recv_window

        response = delete('/fapi/v1/order', params: params)
        Models::Order.new(response)
      end

      # Cancel multiple orders in batch
      # @param symbol [String] Trading symbol
      # @param order_ids [Array<Integer>, nil] List of order IDs to cancel
      # @param client_order_ids [Array<String>, nil] List of client order IDs to cancel
      # @param recv_window [Integer, nil] Receive window
      # @return [Array<Models::Order>] Array of canceled orders
      def batch_cancel(symbol:, order_ids: nil, client_order_ids: nil, recv_window: nil)
        unless order_ids || client_order_ids
          raise ArgumentError,
                'Either order_ids or client_order_ids must be provided'
        end

        params = { symbol: symbol }
        params[:orderIds] = "[#{order_ids.join(',')}]" if order_ids
        params[:origClientOrderIdList] = "[\"#{client_order_ids.join('\",\"')}\"]" if client_order_ids
        params[:recvWindow] = recv_window if recv_window

        response = delete('/fapi/v1/batchOrders', params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end

      # Cancel all open orders for a symbol
      # @param symbol [String] Trading symbol
      # @param recv_window [Integer, nil] Receive window
      # @return [Hash] Response
      def cancel_all(symbol:, recv_window: nil)
        params = { symbol: symbol }
        params[:recvWindow] = recv_window if recv_window

        delete('/fapi/v1/allOpenOrders', params: params)
      end

      # Auto-cancel all open orders after countdown
      # @param symbol [String] Trading symbol (use "" for all symbols)
      # @param countdown_time [Integer] Countdown time in milliseconds (0 to cancel)
      # @return [Hash] Response with countdown time
      def countdown_cancel_all(symbol:, countdown_time:)
        post('/fapi/v1/countdownCancelAll', params: {
               symbol: symbol,
               countdownTime: countdown_time
             })
      end

      # Get order details
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID
      # @param client_order_id [String, nil] Client order ID (alternative to order_id)
      # @param orig_client_order_id [String, nil] Alias for client_order_id
      # @param recv_window [Integer, nil] Receive window
      # @return [Models::Order] Order details
      def find(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, recv_window: nil)
        client_oid = orig_client_order_id || client_order_id
        raise ArgumentError, 'Either order_id or client_order_id must be provided' unless order_id || client_oid

        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_oid if client_oid
        params[:recvWindow] = recv_window if recv_window

        response = get('/fapi/v1/order', params: params)
        Models::Order.new(response)
      end

      # Get a specific open order
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID
      # @param client_order_id [String, nil] Client order ID
      # @return [Models::Order] Open order details
      def open_order(symbol:, order_id: nil, client_order_id: nil)
        raise ArgumentError, 'Either order_id or client_order_id must be provided' unless order_id || client_order_id

        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_order_id if client_order_id

        response = get('/fapi/v1/openOrder', params: params)
        Models::Order.new(response)
      end

      # Get all open orders
      # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
      # @return [Array<Models::Order>] Open orders
      def open_orders(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol

        response = get('/fapi/v1/openOrders', params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end

      # Get all current open orders across all symbols
      # @return [Array<Models::Order>] All open orders
      def all_open_orders
        response = get('/fapi/v1/allOpenOrders', params: {})
        response.map { |order_data| Models::Order.new(order_data) }
      end

      # Get all orders (including filled and canceled)
      # @param symbol [String] Trading symbol
      # @param order_id [Integer, nil] Order ID to start from
      # @param limit [Integer] Number of orders to return (default: 500, max: 1000)
      # @param start_time [Integer, nil] Start time in ms
      # @param end_time [Integer, nil] End time in ms
      # @return [Array<Models::Order>] Orders
      def all_orders(symbol:, order_id: nil, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          limit: limit
        }

        params[:orderId] = order_id if order_id
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time

        response = get('/fapi/v1/allOrders', params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end

      # Get user's trades (fills)
      # @param symbol [String] Trading symbol
      # @param trade_id [Integer, nil] Trade ID to start from
      # @param order_id [Integer, nil] Order ID to filter by
      # @param limit [Integer] Number of trades to return (default: 500, max: 1000)
      # @param start_time [Integer, nil] Start time in ms
      # @param end_time [Integer, nil] End time in ms
      # @return [Array<Models::Trade>] Trades
      def trades(symbol:, trade_id: nil, order_id: nil, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          limit: limit
        }

        params[:tradeId] = trade_id if trade_id
        params[:orderId] = order_id if order_id
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time

        response = get('/fapi/v1/userTrades', params: params)
        response.map { |trade_data| Models::Trade.new(trade_data) }
      end

      # Place multiple orders in batch
      # @param orders [Array<Hash>] Array of order parameters
      #   Each order hash should contain: symbol, side, type, and other order parameters
      # @param recv_window [Integer, nil] Receive window
      # @return [Array<Models::Order>] Array of created orders
      def batch_place(orders:, recv_window: nil)
        formatted_orders = orders.map do |order|
          {
            symbol: order[:symbol],
            side: order[:side].to_s.upcase,
            type: order[:type].to_s.upcase,
            quantity: order[:quantity],
            price: order[:price],
            positionSide: order[:position_side],
            timeInForce: order[:time_in_force],
            reduceOnly: order[:reduce_only],
            newClientOrderId: order[:client_order_id],
            stopPrice: order[:stop_price],
            activationPrice: order[:activation_price],
            callbackRate: order[:callback_rate],
            workingType: order[:working_type],
            priceProtect: order[:price_protect]
          }.compact
        end

        params = {
          batchOrders: JSON.dump(formatted_orders)
        }
        params[:recvWindow] = recv_window if recv_window

        response = post('/fapi/v1/batchOrders', params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end

      # Modify multiple orders in batch
      # @param orders [Array<Hash>] Array of order modification parameters
      #   Each order hash should contain: symbol, and either order_id or client_order_id
      # @param recv_window [Integer, nil] Receive window
      # @return [Array<Models::Order>] Array of modified orders
      def batch_modify(orders:, recv_window: nil)
        formatted_orders = orders.map do |order|
          {
            symbol: order[:symbol],
            orderId: order[:order_id],
            origClientOrderId: order[:client_order_id],
            quantity: order[:quantity],
            price: order[:price],
            newClientOrderId: order[:client_order_id_new]
          }.compact
        end

        params = {
          batchOrders: JSON.dump(formatted_orders)
        }
        params[:recvWindow] = recv_window if recv_window

        response = put('/fapi/v1/batchOrders', params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end
    end
  end
end
