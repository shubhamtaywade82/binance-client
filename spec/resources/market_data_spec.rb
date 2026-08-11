# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::MarketData do
  include_context 'with binance client'

  let(:market_data) { Binance::USDM::Resources::MarketData.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#ping' do
    it 'hits the ping endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/ping}).to_return(status: 200, body: '{}',
                                                                 headers: { 'Content-Type' => 'application/json' })

      expect(market_data.ping).to eq({})
    end
  end

  describe '#server_time' do
    it 'hits the time endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/time})
        .to_return(status: 200, body: { 'serverTime' => 123 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(market_data.server_time['serverTime']).to eq(123)
    end
  end

  describe '#agg_trades' do
    it 'hits the aggTrades endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/aggTrades})
        .to_return(status: 200, body: [{ 'a' => 1, 'p' => '100' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = market_data.agg_trades(symbol: 'BTCUSDT')
      expect(result.first['a']).to eq(1)
    end
  end

  describe '#basis' do
    it 'hits the basis endpoint' do
      stub_request(:get, %r{#{base_url}/futures/data/basis})
        .to_return(status: 200, body: [{ 'basis' => '10' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = market_data.basis(pair: 'BTCUSDT', contract_type: 'PERPETUAL', period: '5m')
      expect(result.first['basis']).to eq('10')
    end
  end

  describe '#rpi_depth' do
    it 'hits the rpiDepth endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/rpiDepth})
        .to_return(status: 200, body: { 'bids' => [], 'asks' => [] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(market_data.rpi_depth(symbol: 'BTCUSDT')).to have_key('bids')
    end
  end
end
