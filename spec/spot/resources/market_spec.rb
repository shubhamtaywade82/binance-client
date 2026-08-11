# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Spot::Resources::Market do
  let(:api) { Binance::Products::API.new(product: :spot) }
  let(:market) { described_class.new(api) }
  let(:base_url) { 'https://api.binance.com' }

  before { WebMock.disable_net_connect!(allow_localhost: true) }

  describe '#klines' do
    it 'returns raw kline arrays' do
      stub_request(:get, "#{base_url}/api/v3/klines")
        .with(query: hash_including(symbol: 'BTCUSDT', interval: '1h'))
        .to_return(status: 200, body: [[1, '50000', '51000']].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(market.klines(symbol: 'BTCUSDT', interval: '1h')).to eq([[1, '50000', '51000']])
    end
  end

  describe '#ticker_24h' do
    it 'wraps a single symbol response in a Ticker model' do
      stub_request(:get, "#{base_url}/api/v3/ticker/24hr")
        .with(query: hash_including(symbol: 'BTCUSDT'))
        .to_return(status: 200, body: { 'symbol' => 'BTCUSDT', 'lastPrice' => '50000' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = market.ticker_24h(symbol: 'BTCUSDT')
      expect(result).to be_a(Binance::Spot::Models::Ticker)
      expect(result.symbol).to eq('BTCUSDT')
    end

    it 'wraps an all-symbols response in an array of Ticker models' do
      stub_request(:get, "#{base_url}/api/v3/ticker/24hr")
        .to_return(status: 200, body: [{ 'symbol' => 'BTCUSDT' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = market.ticker_24h
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Binance::Spot::Models::Ticker)
    end
  end

  describe '#exchange_info' do
    it 'JSON-encodes the symbols array filter' do
      stub_request(:get, "#{base_url}/api/v3/exchangeInfo")
        .with(query: { 'symbols' => '["BTCUSDT","ETHUSDT"]' })
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      expect(market.exchange_info(symbols: %w[BTCUSDT ETHUSDT])).to eq({})
    end
  end
end
