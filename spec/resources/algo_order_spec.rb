# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::AlgoOrder do
  include_context 'with binance client'

  let(:algo_order) { Binance::USDM::Resources::AlgoOrder.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#open' do
    it 'hits the openAlgoOrders endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/openAlgoOrders})
        .to_return(
          status: 200,
          body: { 'total' => 1, 'rows' => [{ 'algoId' => 1, 'symbol' => 'BTCUSDT' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = algo_order.open(symbol: 'BTCUSDT')
      expect(result['rows'].first['algoId']).to eq(1)
    end
  end

  describe '#all' do
    it 'hits the allAlgoOrders endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/allAlgoOrders})
        .to_return(
          status: 200,
          body: { 'total' => 1, 'rows' => [{ 'algoId' => 2, 'symbol' => 'BTCUSDT' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = algo_order.all(symbol: 'BTCUSDT')
      expect(result['rows'].first['algoId']).to eq(2)
    end
  end
end
