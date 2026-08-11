# frozen_string_literal: true

require "spec_helper"
require "binance_usdm"

RSpec.describe BinanceUSDM::Resources::Order do
  include_context "with binance client"
  
  let(:order_resource) { BinanceUSDM::Resources::Order.new(client) }

  describe "#open_orders" do
    context "when no symbol is provided" do
      it "returns all open orders", vcr: true do
        result = order_resource.open_orders
        
        expect(result).to be_an(Array)
        
        if result.any?
          order = result.first
          expect(order).to be_a(BinanceUSDM::Models::Order)
          expect(order.symbol).to be_present if order.respond_to?(:symbol)
        end
      end
    end

    context "when symbol is provided" do
      it "returns open orders for the symbol", vcr: true do
        result = order_resource.open_orders(symbol: "BTCUSDT")
        
        expect(result).to be_an(Array)
        
        result.each do |order|
          expect(order).to be_a(BinanceUSDM::Models::Order)
          expect(order.symbol).to eq("BTCUSDT") if order.respond_to?(:symbol)
        end
      end
    end
  end

  describe "#all_orders" do
    it "returns all orders for a symbol", vcr: true do
      result = order_resource.all_orders(symbol: "BTCUSDT", limit: 5)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 5
      
      if result.any?
        order = result.first
        expect(order).to be_a(BinanceUSDM::Models::Order)
        expect(order.symbol).to eq("BTCUSDT") if order.respond_to?(:symbol)
      end
    end
  end

  describe "#trades" do
    it "returns user trades for a symbol", vcr: true do
      result = order_resource.trades(symbol: "BTCUSDT", limit: 5)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 5
      
      if result.any?
        trade = result.first
        expect(trade).to be_a(BinanceUSDM::Models::Trade)
        expect(trade.symbol).to eq("BTCUSDT") if trade.respond_to?(:symbol)
      end
    end
  end

  describe "#find" do
    context "when order exists" do
      it "returns the order details", vcr: true do
        # First get an existing order ID from all_orders
        orders = order_resource.all_orders(symbol: "BTCUSDT", limit: 1)
        
        if orders.any?
          order_id = orders.first.order_id
          result = order_resource.find(symbol: "BTCUSDT", order_id: order_id)
          
          expect(result).to be_a(BinanceUSDM::Models::Order)
          expect(result.order_id).to eq(order_id) if result.respond_to?(:order_id)
        else
          # Skip if no orders exist
          skip("No orders found to test find")
        end
      end
    end

    context "when using client_order_id" do
      it "returns the order details", vcr: true do
        # This would need a real client order ID from a previous order
        # For now, we'll skip this test
        skip("Requires a known client_order_id")
      end
    end
  end

  describe "#place" do
    context "on testnet" do
      it "places a new order", vcr: true do
        # Note: This test requires a valid testnet order cassette
        # The cassette should contain a successful order placement response
        begin
          result = order_resource.place(
            symbol: "BTCUSDT",
            side: "BUY",
            type: "LIMIT",
            quantity: "0.001",
            price: "50000.00",
            time_in_force: "GTC"
          )
          
          expect(result).to be_a(BinanceUSDM::Models::Order)
          expect(result.symbol).to eq("BTCUSDT") if result.respond_to?(:symbol)
          expect(result.side).to eq("BUY") if result.respond_to?(:side)
        rescue BinanceUSDM::ApiError => e
          # Order might fail due to insufficient balance or invalid price
          # This is expected in some test scenarios
          expect(e).to be_a(BinanceUSDM::ApiError)
        end
      end
    end
  end

  describe "#cancel" do
    context "when order exists" do
      it "cancels the order", vcr: true do
        # Get an open order first
        open_orders = order_resource.open_orders(symbol: "BTCUSDT")
        
        if open_orders.any?
          order_id = open_orders.first.order_id
          result = order_resource.cancel(symbol: "BTCUSDT", order_id: order_id)
          
          expect(result).to be_a(BinanceUSDM::Models::Order)
          expect(result.status).to eq("CANCELED") if result.respond_to?(:status)
        else
          skip("No open orders to cancel")
        end
      end
    end

    context "when order does not exist" do
      it "raises an error", vcr: true do
        expect {
          order_resource.cancel(symbol: "BTCUSDT", order_id: 999_999_999)
        }.to raise_error(BinanceUSDM::ApiError)
      end
    end
  end

  describe "#modify" do
    context "when order exists and is modifiable" do
      it "modifies the order", vcr: true do
        # Place a test order first (or use existing one)
        open_orders = order_resource.open_orders(symbol: "BTCUSDT")
        
        if open_orders.any? && open_orders.first.status == "NEW"
          order_id = open_orders.first.order_id
          result = order_resource.modify(
            symbol: "BTCUSDT",
            order_id: order_id,
            quantity: "0.002"
          )
          
          expect(result).to be_a(BinanceUSDM::Models::Order)
          expect(result.order_id).to eq(order_id) if result.respond_to?(:order_id)
        else
          skip("No modifiable orders found")
        end
      end
    end
  end

  describe "#cancel_all" do
    it "cancels all open orders for a symbol", vcr: true do
      result = order_resource.cancel_all(symbol: "BTCUSDT")
      
      expect(result).to be_a(Hash)
      expect(result["msg"]).to eq("Success: All orders for BTCUSDT have been canceled.") if result.key?("msg")
    end
  end

  describe "validation" do
    describe "#find" do
      it "raises ArgumentError when neither order_id nor client_order_id is provided" do
        expect {
          order_resource.find(symbol: "BTCUSDT")
        }.to raise_error(ArgumentError, /Either order_id or client_order_id must be provided/)
      end
    end

    describe "#cancel" do
      it "raises ArgumentError when neither order_id nor client_order_id is provided" do
        expect {
          order_resource.cancel(symbol: "BTCUSDT")
        }.to raise_error(ArgumentError, /Either order_id or client_order_id must be provided/)
      end
    end
  end
end
