# frozen_string_literal: true

require_relative "../core/base_api"
require_relative "../models"

module BinanceUSDM
  module Resources
    # Order resource for managing futures orders.
    class Order < BaseAPI
      # Place a new order
      # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
      # @param side [String] Order side: BUY or SELL
      # @param type [String] Order type: LIMIT, MARKET, STOP, etc.
      # @param quantity [String] Order quantity
      # @param price [String] Limit price (required for LIMIT orders)
      # @param position_side [String] Position side: BOTH, LONG, SHORT (default: BOTH)
      # @param time_in_force [String] Time in force: GTC, IOC, FOK (default: GTC)
      # @param client_order_id [String] Client order ID (optional)
      # @param stop_price [String] Stop price (for STOP orders)
      # @return [Models::Order] Created order
      def place(symbol:, side:, type:, quantity:, price: nil, position_side: "BOTH",
                time_in_force: "GTC", client_order_id: nil, stop_price: nil)
        params = {
          symbol: symbol,
          side: side,
          type: type,
          quantity: quantity,
          positionSide: position_side,
          timeInForce: time_in_force
        }
        
        params[:price] = price if price
        params[:clientOrderId] = client_order_id if client_order_id
        params[:stopPrice] = stop_price if stop_price
        
        response = post("/fapi/v1/order", params: params)
        Models::Order.new(response)
      end
      
      # Modify an existing order
      # @param symbol [String] Trading symbol
      # @param order_id [Integer] Order ID
      # @param quantity [String] New quantity
      # @param price [String] New price
      # @return [Models::Order] Modified order
      def modify(symbol:, order_id:, quantity: nil, price: nil)
        params = {
          symbol: symbol,
          orderId: order_id
        }
        
        params[:quantity] = quantity if quantity
        params[:price] = price if price
        
        response = put("/fapi/v1/order", params: params)
        Models::Order.new(response)
      end
      
      # Cancel an order
      # @param symbol [String] Trading symbol
      # @param order_id [Integer] Order ID
      # @param client_order_id [String] Client order ID (alternative to order_id)
      # @return [Models::Order] Canceled order
      def cancel(symbol:, order_id: nil, client_order_id: nil)
        raise ArgumentError, "Either order_id or client_order_id must be provided" unless order_id || client_order_id
        
        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_order_id if client_order_id
        
        response = delete("/fapi/v1/order", params: params)
        Models::Order.new(response)
      end
      
      # Cancel all open orders for a symbol
      # @param symbol [String] Trading symbol
      # @return [Hash] Response
      def cancel_all(symbol:)
        delete("/fapi/v1/allOpenOrders", params: { symbol: symbol })
      end
      
      # Get order details
      # @param symbol [String] Trading symbol
      # @param order_id [Integer] Order ID
      # @param client_order_id [String] Client order ID (alternative to order_id)
      # @return [Models::Order] Order details
      def find(symbol:, order_id: nil, client_order_id: nil)
        raise ArgumentError, "Either order_id or client_order_id must be provided" unless order_id || client_order_id
        
        params = { symbol: symbol }
        params[:orderId] = order_id if order_id
        params[:origClientOrderId] = client_order_id if client_order_id
        
        response = get("/fapi/v1/order", params: params)
        Models::Order.new(response)
      end
      
      # Get all open orders
      # @param symbol [String] Trading symbol (optional, all symbols if not provided)
      # @return [Array<Models::Order>] Open orders
      def open_orders(symbol: nil)
        params = {}
        params[:symbol] = symbol if symbol
        
        response = get("/fapi/v1/openOrders", params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end
      
      # Get all orders (including filled and canceled)
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Number of orders to return (default: 500, max: 1000)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Models::Order>] Orders
      def all_orders(symbol:, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        response = get("/fapi/v1/allOrders", params: params)
        response.map { |order_data| Models::Order.new(order_data) }
      end
      
      # Get user's trades
      # @param symbol [String] Trading symbol
      # @param limit [Integer] Number of trades to return (default: 500, max: 1000)
      # @param start_time [Integer] Start time in ms (optional)
      # @param end_time [Integer] End time in ms (optional)
      # @return [Array<Models::Trade>] Trades
      def trades(symbol:, limit: 500, start_time: nil, end_time: nil)
        params = {
          symbol: symbol,
          limit: limit
        }
        
        params[:startTime] = start_time if start_time
        params[:endTime] = end_time if end_time
        
        response = get("/fapi/v1/userTrades", params: params)
        response.map { |trade_data| Models::Trade.new(trade_data) }
      end
    end
  end
end
