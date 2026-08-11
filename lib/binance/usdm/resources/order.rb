# frozen_string_literal: true

require_relative '../core/base_api'
require_relative '../models'

module Binance
  module USDM
    module Resources
      # Maps order option keywords to Binance API parameters.
      # `enum: true` values are uppercased (API expects ENUM strings).
      ORDER_OPTIONS = {
        quantity: { param: :quantity },
        price: { param: :price },
        position_side: { param: :positionSide, enum: true },
        time_in_force: { param: :timeInForce, enum: true },
        reduce_only: { param: :reduceOnly },
        close_position: { param: :closePosition },
        client_order_id: { param: :newClientOrderId },
        response_type: { param: :newOrderRespType, enum: true },
        stop_price: { param: :stopPrice },
        activation_price: { param: :activationPrice },
        callback_rate: { param: :callbackRate },
        working_type: { param: :workingType, enum: true },
        price_protect: { param: :priceProtect },
        price_match: { param: :priceMatch, enum: true },
        self_trade_prevention_mode: { param: :selfTradePreventionMode, enum: true },
        good_till_date: { param: :goodTillDate },
        recv_window: { param: :recvWindow }
      }.freeze

      # Class-level (ActiveRecord-style) accessors for the order resource.
      module OrderClassMethods
        # Get the client to use (thread-local or default)
        def client
          Thread.current[:binance_usdm_client] || Binance::USDM.default_client
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
        # @example Binance::USDM::Resources::Order.create(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
        def create(symbol:, side:, type:, **kwargs)
          client.order.place(symbol: symbol, side: side, type: type, **kwargs)
        end

        # Find an order by ID or client_order_id (class method)
        # @example Binance::USDM::Resources::Order.find(symbol: "ETHUSDT", order_id: 123456)
        def find(symbol:, order_id: nil, client_order_id: nil, **kwargs)
          client.order.find(symbol: symbol, order_id: order_id, client_order_id: client_order_id, **kwargs)
        end

        # Get open orders (class method)
        # @example Binance::USDM::Resources::Order.open(symbol: "ETHUSDT")
        def open(symbol: nil, **_kwargs)
          symbol ? client.order.open_orders(symbol: symbol) : client.order.all_open_orders
        end

        # Cancel an order (class method)
        # @example Binance::USDM::Resources::Order.cancel(symbol: "ETHUSDT", order_id: 123456)
        def cancel(symbol:, order_id: nil, client_order_id: nil, **kwargs)
          client.order.cancel(symbol: symbol, order_id: order_id, client_order_id: client_order_id, **kwargs)
        end

        # Cancel all orders for a symbol (class method)
        # @example Binance::USDM::Resources::Order.cancel_all(symbol: "ETHUSDT")
        def cancel_all(symbol:, **kwargs)
          client.order.cancel_all(symbol: symbol, **kwargs)
        end

        # Batch create orders (class method)
        # @example Binance::USDM::Resources::Order.batch_create([{symbol: "ETHUSDT", ...}, {symbol: "BTCUSDT", ...}])
        def batch_create(orders_array, **kwargs)
          client.order.batch_place(orders: orders_array, **kwargs)
        end

        # Batch cancel orders (class method)
        # @example Binance::USDM::Resources::Order.batch_cancel(symbol: "ETHUSDT", order_ids: [123, 456])
        def batch_cancel(symbol:, order_ids: nil, client_order_ids: nil, **kwargs)
          client.order.batch_cancel(symbol: symbol, order_ids: order_ids, client_order_ids: client_order_ids, **kwargs)
        end
      end

      # Order write operations (create, modify, cancel) and shared payload builders.
      module OrderCommands
        # Place a new order
        # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
        # @param side [String, Symbol] Order side: BUY or SELL
        # @param type [String, Symbol] Order type: LIMIT, MARKET, STOP, STOP_MARKET, TAKE_PROFIT,
        #   TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET
        # @param quantity [String, nil] Order quantity (not required for closePosition orders)
        # @param price [String, nil] Limit price (required for LIMIT orders)
        # @param position_side [String, nil] Position side: BOTH, LONG, SHORT
        #   (default: BOTH for One-way Mode; required for Hedge Mode)
        # @param time_in_force [String, nil] Time in force: GTC, IOC, FOK (default: GTC for LIMIT)
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
        def place(symbol:, side:, type:, **options)
          options[:client_order_id] ||= options.delete(:new_client_order_id)

          response = post('/fapi/v1/order', params: order_payload(symbol: symbol, side: side, type: type, **options))
          Models::Order.new(response)
        end

        # Test order creation (signature checked but order not sent to matching engine)
        # @param symbol [String] Trading symbol
        # @param side [String, Symbol] Order side
        # @param type [String, Symbol] Order type
        # @param options [Hash] Any order parameters (see OrderCommands#place)
        # @return [Hash] Empty response if successful
        def test(symbol:, side:, type:, **options)
          post('/fapi/v1/order/test', params: order_payload(symbol: symbol, side: side, type: type, **options))
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
        def modify(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, side: nil, # rubocop:disable Metrics/ParameterLists
                   quantity: nil, price: nil, client_order_id_new: nil, recv_window: nil)
          params = order_ref_params(symbol,
                                    order_id: order_id, client_order_id: orig_client_order_id || client_order_id,
                                    recv_window: recv_window)
          params[:side] = side.to_s.upcase if side
          params[:quantity] = quantity if quantity
          params[:price] = price if price
          params[:newClientOrderId] = client_order_id_new if client_order_id_new

          Models::Order.new(put('/fapi/v1/order', params: params))
        end

        # Cancel an active order
        # @param symbol [String] Trading symbol
        # @param order_id [Integer, nil] Order ID
        # @param client_order_id [String, nil] Client order ID
        # @param orig_client_order_id [String, nil] Alias for client_order_id
        # @param recv_window [Integer, nil] Receive window
        # @return [Models::Order] Canceled order
        def cancel(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, recv_window: nil)
          params = order_ref_params(symbol,
                                    order_id: order_id, client_order_id: orig_client_order_id || client_order_id,
                                    recv_window: recv_window)

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
          post('/fapi/v1/countdownCancelAll', params: { symbol: symbol, countdownTime: countdown_time })
        end

        # Place multiple orders in batch
        # @param orders [Array<Hash>] Array of order parameters
        #   Each order hash should contain: symbol, side, type, and other order parameters
        # @param recv_window [Integer, nil] Receive window
        # @return [Array<Models::Order>] Array of created orders
        def batch_place(orders:, recv_window: nil)
          params = { batchOrders: JSON.dump(batch_order_payload(orders)) }
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
          params = { batchOrders: JSON.dump(batch_modify_payload(orders)) }
          params[:recvWindow] = recv_window if recv_window

          response = put('/fapi/v1/batchOrders', params: params)
          response.map { |order_data| Models::Order.new(order_data) }
        end

        private

        def order_payload(symbol:, side:, type:, **options)
          unknown = options.keys - ORDER_OPTIONS.keys
          raise ArgumentError, "Unknown order option(s): #{unknown.join(', ')}" if unknown.any?

          params = { symbol: symbol, side: side.to_s.upcase, type: type.to_s.upcase }
          options.each { |key, value| add_order_param(params, key, value) }
          params
        end

        def add_order_param(params, key, value)
          return unless value

          rule = ORDER_OPTIONS[key]
          params[rule[:param]] = rule[:enum] ? value.to_s.upcase : value
        end

        def order_ref_params(symbol, order_id: nil, client_order_id: nil, recv_window: nil)
          raise ArgumentError, 'Either order_id or client_order_id must be provided' unless order_id || client_order_id

          params = { symbol: symbol }
          params[:orderId] = order_id if order_id
          params[:origClientOrderId] = client_order_id if client_order_id
          params[:recvWindow] = recv_window if recv_window
          params
        end

        def batch_order_payload(orders)
          orders.map { |order| order_payload(**order) }
        end

        def batch_modify_payload(orders)
          orders.map do |order|
            {
              symbol: order[:symbol],
              orderId: order[:order_id],
              origClientOrderId: order[:client_order_id],
              quantity: order[:quantity],
              price: order[:price],
              newClientOrderId: order[:client_order_id_new]
            }.compact
          end
        end
      end

      # Order read operations (queries and order history).
      module OrderQueries
        # Get order details
        # @param symbol [String] Trading symbol
        # @param order_id [Integer, nil] Order ID
        # @param client_order_id [String, nil] Client order ID (alternative to order_id)
        # @param orig_client_order_id [String, nil] Alias for client_order_id
        # @param recv_window [Integer, nil] Receive window
        # @return [Models::Order] Order details
        def find(symbol:, order_id: nil, client_order_id: nil, orig_client_order_id: nil, recv_window: nil)
          params = order_ref_params(symbol,
                                    order_id: order_id, client_order_id: orig_client_order_id || client_order_id,
                                    recv_window: recv_window)

          response = get('/fapi/v1/order', params: params)
          Models::Order.new(response)
        end

        # Get a specific open order
        # @param symbol [String] Trading symbol
        # @param order_id [Integer, nil] Order ID
        # @param client_order_id [String, nil] Client order ID
        # @return [Models::Order] Open order details
        def open_order(symbol:, order_id: nil, client_order_id: nil)
          params = order_ref_params(symbol, order_id: order_id, client_order_id: client_order_id)

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
          params = { symbol: symbol, limit: limit }
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
          params = { symbol: symbol, limit: limit }
          params[:tradeId] = trade_id if trade_id
          params[:orderId] = order_id if order_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          response = get('/fapi/v1/userTrades', params: params)
          response.map { |trade_data| Models::Trade.new(trade_data) }
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
          params = { symbol: symbol, limit: limit }
          params[:orderId] = order_id if order_id
          params[:origClientOrderId] = client_order_id if client_order_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          get('/fapi/v1/orderAmendment', params: params)
        end

        # Get user's force (liquidation) orders
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @param auto_close_type [String, nil] LIQUIDATION or ADL
        # @param start_time [Integer, nil] Start time in ms
        # @param end_time [Integer, nil] End time in ms
        # @param limit [Integer] Number of results (default: 50, max: 100)
        # @return [Array<Models::Order>] Force orders
        def force_orders(symbol: nil, auto_close_type: nil, start_time: nil, end_time: nil, limit: 50)
          params = { limit: limit }
          params[:symbol] = symbol if symbol
          params[:autoCloseType] = auto_close_type if auto_close_type
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          response = get('/fapi/v1/forceOrders', params: params)
          response.map { |order_data| Models::Order.new(order_data) }
        end
      end

      # Order resource for managing futures orders.
      # Implements all Binance USDⓈ-M Futures order endpoints.
      # Supports both instance methods (via client) and class methods (via default_client).
      class Order < BaseAPI
        extend OrderClassMethods
        include OrderCommands
        include OrderQueries
      end
    end
  end
end
