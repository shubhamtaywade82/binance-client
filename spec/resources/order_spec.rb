# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::Order do
  include_context 'with binance client'

  let(:order_resource) { Binance::USDM::Resources::Order.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#open_orders' do
    it 'returns open orders for a symbol' do
      stub_request(:get, %r{#{base_url}/fapi/v1/openOrders})
        .to_return(
          status: 200,
          body: [{ 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'status' => 'NEW', 'side' => 'BUY',
                   'origQty' => '1.0' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.open_orders(symbol: 'BTCUSDT')
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Binance::USDM::Models::Order)
      expect(result.first.order_id).to eq(12_345)
      expect(result.first.active?).to be(true)
    end
  end

  describe '#all_orders' do
    it 'returns all orders for a symbol' do
      stub_request(:get, %r{#{base_url}/fapi/v1/allOrders})
        .to_return(
          status: 200,
          body: [{ 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'status' => 'FILLED', 'side' => 'BUY' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.all_orders(symbol: 'BTCUSDT', limit: 5)
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Binance::USDM::Models::Order)
      expect(result.first.filled?).to be(true)
    end
  end

  describe '#trades' do
    it 'returns user trades for a symbol' do
      stub_request(:get, %r{#{base_url}/fapi/v1/userTrades})
        .to_return(
          status: 200,
          body: [{ 'id' => 101, 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'price' => '50000.00',
                   'qty' => '0.1' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.trades(symbol: 'BTCUSDT', limit: 5)
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Binance::USDM::Models::Trade)
      expect(result.first.id).to eq(101)
      expect(result.first.price).to eq('50000.00')
    end
  end

  describe '#find' do
    it 'returns the order details by order_id' do
      stub_request(:get, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'status' => 'NEW', 'price' => '50000.00' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.find(symbol: 'BTCUSDT', order_id: 12_345)
      expect(result).to be_a(Binance::USDM::Models::Order)
      expect(result.order_id).to eq(12_345)
    end

    it 'returns the order details by orig_client_order_id' do
      stub_request(:get, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 12_345, 'clientOrderId' => 'my_id_1', 'symbol' => 'BTCUSDT', 'status' => 'NEW' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.find(symbol: 'BTCUSDT', orig_client_order_id: 'my_id_1')
      expect(result).to be_a(Binance::USDM::Models::Order)
      expect(result.client_order_id).to eq('my_id_1')
    end
  end

  describe '#place' do
    it 'places a limit order' do
      stub_request(:post, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'side' => 'BUY', 'type' => 'LIMIT',
                  'status' => 'NEW' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.place(
        symbol: 'BTCUSDT',
        side: 'BUY',
        type: 'LIMIT',
        quantity: '0.001',
        price: '50000.00',
        time_in_force: 'GTC'
      )

      expect(result).to be_a(Binance::USDM::Models::Order)
      expect(result.order_id).to eq(12_345)
      expect(result.side).to eq('BUY')
    end
  end

  describe '#cancel' do
    it 'cancels an order by order_id' do
      stub_request(:delete, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'status' => 'CANCELED' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.cancel(symbol: 'BTCUSDT', order_id: 12_345)
      expect(result).to be_a(Binance::USDM::Models::Order)
      expect(result.canceled?).to be(true)
    end
  end

  describe '#modify' do
    it 'modifies an order' do
      stub_request(:put, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 12_345, 'symbol' => 'BTCUSDT', 'price' => '51000.00', 'status' => 'NEW' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.modify(
        symbol: 'BTCUSDT',
        order_id: 12_345,
        side: 'BUY',
        quantity: '0.002',
        price: '51000.00'
      )

      expect(result).to be_a(Binance::USDM::Models::Order)
      expect(result.price).to eq('51000.00')
    end
  end

  describe '#cancel_all' do
    it 'cancels all open orders for a symbol' do
      stub_request(:delete, %r{#{base_url}/fapi/v1/allOpenOrders})
        .to_return(
          status: 200,
          body: { 'code' => 200, 'msg' => 'Success: All orders for BTCUSDT have been canceled.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.cancel_all(symbol: 'BTCUSDT')
      expect(result['msg']).to match(/Success/)
    end
  end

  describe '#batch operations' do
    it 'places batch orders' do
      stub_request(:post, %r{#{base_url}/fapi/v1/batchOrders})
        .to_return(
          status: 200,
          body: [{ 'orderId' => 12_345 }, { 'orderId' => 12_346 }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      orders = [
        { symbol: 'BTCUSDT', side: 'BUY', type: 'LIMIT', quantity: '0.001', price: '50000' },
        { symbol: 'BTCUSDT', side: 'BUY', type: 'LIMIT', quantity: '0.002', price: '49000' }
      ]
      result = order_resource.batch_place(orders: orders)
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'cancels batch orders' do
      stub_request(:delete, %r{#{base_url}/fapi/v1/batchOrders})
        .to_return(
          status: 200,
          body: [{ 'orderId' => 12_345 }, { 'orderId' => 12_346 }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.batch_cancel(symbol: 'BTCUSDT', order_ids: [12_345, 12_346])
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end

  describe '#modify_history' do
    it 'hits the orderAmendment endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/orderAmendment})
        .to_return(
          status: 200,
          body: [{ 'amendmentId' => 1, 'symbol' => 'BTCUSDT', 'orderId' => 12_345 }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = order_resource.modify_history(symbol: 'BTCUSDT', order_id: 12_345)
      expect(result.first['amendmentId']).to eq(1)
    end
  end

  describe 'validation' do
    it 'raises ArgumentError when neither order_id nor orig_client_order_id is provided to find' do
      expect do
        order_resource.find(symbol: 'BTCUSDT')
      end.to raise_error(ArgumentError, /Either order_id or client_order_id must be provided/)
    end

    it 'raises ArgumentError when neither order_id nor orig_client_order_id is provided to cancel' do
      expect do
        order_resource.cancel(symbol: 'BTCUSDT')
      end.to raise_error(ArgumentError, /Either order_id or client_order_id must be provided/)
    end
  end

  describe 'class methods' do
    it 'creates an order using ActiveRecord-style class method' do
      stub_request(:post, %r{#{base_url}/fapi/v1/order})
        .to_return(
          status: 200,
          body: { 'orderId' => 9999, 'symbol' => 'BTCUSDT', 'side' => 'BUY', 'status' => 'NEW' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      Binance::USDM::Resources::Order.using(client) do
        res = Binance::USDM::Resources::Order.create(
          symbol: 'BTCUSDT',
          side: 'BUY',
          type: 'LIMIT',
          quantity: '0.01',
          price: '50000.00'
        )
        expect(res.order_id).to eq(9999)
      end
    end
  end
end
