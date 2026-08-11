# frozen_string_literal: true

require_relative 'base'
require_relative '../models'

module Binance
  module Spot
    module Resources
      # Maps order option keywords to Binance API parameters.
      # `enum: true` values are uppercased (API expects ENUM strings).
      ORDER_OPTIONS = {
        time_in_force: { param: :timeInForce, enum: true },
        quantity: { param: :quantity },
        quote_order_qty: { param: :quoteOrderQty },
        price: { param: :price },
        client_order_id: { param: :newClientOrderId },
        stop_price: { param: :stopPrice },
        trailing_delta: { param: :trailingDelta },
        iceberg_qty: { param: :icebergQty },
        response_type: { param: :newOrderRespType, enum: true },
        self_trade_prevention_mode: { param: :selfTradePreventionMode, enum: true },
        strategy_id: { param: :strategyId },
        strategy_type: { param: :strategyType },
        peg_price_type: { param: :pegPriceType, enum: true },
        peg_offset_type: { param: :pegOffsetType, enum: true },
        peg_offset_value: { param: :pegOffsetValue },
        recv_window: { param: :recvWindow }
      }.freeze

      # Order write operations (place, modify, cancel) and shared payload builders.
      module OrderCommands
        # Place a new order
        # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
        # @param side [String, Symbol] BUY or SELL
        # @param type [String, Symbol] LIMIT, MARKET, STOP_LOSS, STOP_LOSS_LIMIT,
        #   TAKE_PROFIT, TAKE_PROFIT_LIMIT, LIMIT_MAKER
        # @param options [Hash] see ORDER_OPTIONS
        # @return [Models::Order] Created order
        def place(symbol:, side:, type:, **options)
          response = @api.request(:post_api_v3_order, order_payload(symbol: symbol, side: side, type: type, **options))
          Models::Order.new(response)
        end

        # Test order creation (signature checked but order not sent to matching engine)
        def test(symbol:, side:, type:, **options)
          @api.request(:post_api_v3_order_test, order_payload(symbol: symbol, side: side, type: type, **options))
        end

        # Cancel and replace an order in one atomic request
        # @param cancel_replace_mode [String] STOP_ON_FAILURE or ALLOW_FAILURE
        # @param cancel_order_id [Integer, nil] Order ID to cancel
        # @param cancel_client_order_id [String, nil] Client order ID to cancel (alternative to cancel_order_id)
        def cancel_replace(symbol:, side:, type:, cancel_replace_mode:, **options)
          cancel_order_id = options.delete(:cancel_order_id)
          cancel_client_order_id = options.delete(:cancel_client_order_id)
          unless cancel_order_id || cancel_client_order_id
            raise ArgumentError, 'Either cancel_order_id or cancel_client_order_id must be provided'
          end

          params = order_payload(symbol: symbol, side: side, type: type, **options)
          params[:cancelReplaceMode] = cancel_replace_mode
          params[:cancelOrderId] = cancel_order_id if cancel_order_id
          params[:cancelOrigClientOrderId] = cancel_client_order_id if cancel_client_order_id

          @api.request(:post_api_v3_order_cancelreplace, params)
        end

        # Reduce the quantity of an existing order while keeping its book priority
        # @param new_qty [String] New quantity (must be > 0 and < current quantity)
        def amend_keep_priority(symbol:, new_qty:, order_id: nil, client_order_id: nil, recv_window: nil)
          params = order_ref_params(symbol, order_id: order_id, client_order_id: client_order_id,
                                            recv_window: recv_window)
          params[:newQty] = new_qty

          @api.request(:put_api_v3_order_amend_keeppriority, params)
        end

        # Cancel an active order
        def cancel(symbol:, order_id: nil, client_order_id: nil, recv_window: nil)
          params = order_ref_params(symbol, order_id: order_id, client_order_id: client_order_id,
                                            recv_window: recv_window)

          Models::Order.new(@api.request(:delete_api_v3_order, params))
        end

        # Cancel all open orders on a symbol
        def cancel_all(symbol:, recv_window: nil)
          params = { symbol: symbol }
          params[:recvWindow] = recv_window if recv_window

          response = @api.request(:delete_api_v3_openorders, params)
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
      end

      # Order read operations (queries and order history).
      module OrderQueries
        # Get order details
        def find(symbol:, order_id: nil, client_order_id: nil, recv_window: nil)
          params = order_ref_params(symbol, order_id: order_id, client_order_id: client_order_id,
                                            recv_window: recv_window)

          Models::Order.new(@api.request(:get_api_v3_order, params))
        end

        # Get all open orders
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        def open_orders(symbol: nil)
          params = symbol ? { symbol: symbol } : {}

          response = @api.request(:get_api_v3_openorders, params)
          response.map { |order_data| Models::Order.new(order_data) }
        end

        # Get all orders (including filled and canceled)
        def all_orders(symbol:, order_id: nil, start_time: nil, end_time: nil, limit: 500)
          params = { symbol: symbol, limit: limit }
          params[:orderId] = order_id if order_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          response = @api.request(:get_api_v3_allorders, params)
          response.map { |order_data| Models::Order.new(order_data) }
        end

        # Get order amendment (amend_keep_priority) history
        def amendments(symbol:, order_id: nil, start_time: nil, end_time: nil, limit: 500)
          params = { symbol: symbol, limit: limit }
          params[:orderId] = order_id if order_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          @api.request(:get_api_v3_order_amendments, params)
        end

        # Get current unfilled order count against the exchange rate limits
        def rate_limit
          @api.request(:get_api_v3_ratelimit_order)
        end
      end

      # One-Cancels-the-Other / multi-leg order lists (OCO, OTO, OTOCO, OPO, OPOCO).
      # These accept raw Binance parameter names (many conditional combinations —
      # see https://developers.binance.com/docs/binance-spot-api-docs/rest-api/trading-endpoints)
      # rather than a fully-typed wrapper.
      module OrderLists
        def oco(**params)
          @api.request(:post_api_v3_orderlist_oco, params)
        end

        def oto(**params)
          @api.request(:post_api_v3_orderlist_oto, params)
        end

        def otoco(**params)
          @api.request(:post_api_v3_orderlist_otoco, params)
        end

        def cancel_order_list(symbol:, order_list_id: nil, client_order_id: nil, recv_window: nil)
          unless order_list_id || client_order_id
            raise ArgumentError, 'Either order_list_id or client_order_id must be provided'
          end

          params = { symbol: symbol }
          params[:orderListId] = order_list_id if order_list_id
          params[:listClientOrderId] = client_order_id if client_order_id
          params[:recvWindow] = recv_window if recv_window

          @api.request(:delete_api_v3_orderlist, params)
        end

        def order_list(order_list_id: nil, client_order_id: nil)
          unless order_list_id || client_order_id
            raise ArgumentError, 'Either order_list_id or client_order_id must be provided'
          end

          params = {}
          params[:orderListId] = order_list_id if order_list_id
          params[:origClientOrderId] = client_order_id if client_order_id

          @api.request(:get_api_v3_orderlist, params)
        end

        def all_order_lists(from_id: nil, start_time: nil, end_time: nil, limit: 500)
          params = { limit: limit }
          params[:fromId] = from_id if from_id
          params[:startTime] = start_time if start_time
          params[:endTime] = end_time if end_time

          @api.request(:get_api_v3_allorderlist, params)
        end

        def open_order_lists
          @api.request(:get_api_v3_openorderlist)
        end
      end

      # Spot order resource: single orders, order lists, and SOR routing.
      class Order < Base
        include OrderCommands
        include OrderQueries
        include OrderLists

        # Place a new order routed through Smart Order Routing (SOR)
        def sor_place(symbol:, side:, quantity:, **options)
          params = order_payload(symbol: symbol, side: side, type: options.delete(:type) || 'MARKET', **options)
          Models::Order.new(@api.request(:post_api_v3_sor_order, params.merge(quantity: quantity)))
        end
      end
    end
  end
end
