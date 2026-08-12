# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Spot::Resources::Order do
  let(:api) { Binance::Products::API.new(product: :spot, api_key: 'k', secret_key: 's') }
  let(:order) { described_class.new(api) }
  let(:base_url) { 'https://api.binance.com' }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(api.clock).to receive(:sync_needed?).and_return(false)
  end

  describe '#place' do
    it 'places a limit order and returns a typed Order' do
      stub_request(:post, "#{base_url}/api/v3/order")
        .with(body: hash_including('symbol' => 'BTCUSDT', 'side' => 'BUY', 'type' => 'LIMIT',
                                   'timeInForce' => 'GTC', 'quantity' => '0.01', 'price' => '50000'))
        .to_return(status: 200, body: { 'orderId' => 1, 'symbol' => 'BTCUSDT', 'status' => 'NEW' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = order.place(symbol: 'BTCUSDT', side: :buy, type: :limit, quantity: '0.01', price: '50000',
                           time_in_force: :gtc)
      expect(result).to be_a(Binance::Spot::Models::Order)
      expect(result.active?).to be(true)
    end

    it 'raises on unknown order options' do
      expect do
        order.place(symbol: 'BTCUSDT', side: :buy, type: :limit, bogus_option: 1)
      end.to raise_error(ArgumentError, /Unknown order option/)
    end
  end

  describe '#cancel' do
    it 'requires order_id or client_order_id' do
      expect { order.cancel(symbol: 'BTCUSDT') }.to raise_error(ArgumentError, /order_id or client_order_id/)
    end

    it 'cancels an order' do
      stub_request(:delete, %r{#{base_url}/api/v3/order(\?|$)})
        .to_return(status: 200, body: { 'orderId' => 1, 'symbol' => 'BTCUSDT', 'status' => 'CANCELED' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = order.cancel(symbol: 'BTCUSDT', order_id: 1)
      expect(result.canceled?).to be(true)
    end
  end

  describe '#cancel_replace' do
    it 'requires cancel_order_id or cancel_client_order_id' do
      expect do
        order.cancel_replace(symbol: 'BTCUSDT', side: :buy, type: :market, cancel_replace_mode: 'STOP_ON_FAILURE',
                             quantity: '0.01')
      end.to raise_error(ArgumentError, /cancel_order_id or cancel_client_order_id/)
    end

    it 'hits the cancelReplace endpoint' do
      stub_request(:post, "#{base_url}/api/v3/order/cancelReplace")
        .with(body: hash_including('cancelReplaceMode' => 'STOP_ON_FAILURE', 'cancelOrderId' => '1'))
        .to_return(status: 200, body: { 'orderId' => 2 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = order.cancel_replace(symbol: 'BTCUSDT', side: :buy, type: :market,
                                    cancel_replace_mode: 'STOP_ON_FAILURE', cancel_order_id: 1, quote_order_qty: '10')
      expect(result['orderId']).to eq(2)
    end
  end

  describe '#open_orders' do
    it 'returns typed orders' do
      stub_request(:get, %r{#{base_url}/api/v3/openOrders})
        .to_return(status: 200, body: [{ 'orderId' => 1, 'symbol' => 'BTCUSDT', 'status' => 'NEW' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = order.open_orders(symbol: 'BTCUSDT')
      expect(result.first).to be_a(Binance::Spot::Models::Order)
    end
  end

  describe '#oco' do
    it 'passes raw params through to the orderList/oco endpoint' do
      stub_request(:post, "#{base_url}/api/v3/orderList/oco")
        .with(body: hash_including('symbol' => 'BTCUSDT', 'aboveType' => 'LIMIT_MAKER'))
        .to_return(status: 200, body: { 'orderListId' => 1 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = order.oco(symbol: 'BTCUSDT', side: 'SELL', quantity: '0.01', aboveType: 'LIMIT_MAKER',
                         belowType: 'STOP_LOSS', belowStopPrice: '40000')
      expect(result['orderListId']).to eq(1)
    end
  end
end
