# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Products::API do
  let(:api) { described_class.new(product: :spot, api_key: 'k', secret_key: 's') }
  let(:base_url) { 'https://api.binance.com' }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(api.clock).to receive(:sync_needed?).and_return(false)
  end

  describe '#request' do
    it 'executes a public GET endpoint' do
      stub_request(:get, "#{base_url}/api/v3/time").to_return(status: 200, body: { 'serverTime' => 123 }.to_json,
                                                              headers: { 'Content-Type' => 'application/json' })

      expect(api.request(:get_api_v3_time)['serverTime']).to eq(123)
    end

    it 'sends params as query string for GET' do
      stub_request(:get, "#{base_url}/api/v3/klines")
        .with(query: { symbol: 'BTCUSDT', interval: '1h', limit: '2' })
        .to_return(status: 200, body: [[1, '63608', '0.001']].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = api.request(:get_api_v3_klines, symbol: 'BTCUSDT', interval: '1h', limit: 2)
      expect(result).to eq([[1, '63608', '0.001']])
    end

    it 'sends params as form body for POST' do
      stub_request(:post, "#{base_url}/api/v3/order")
        .with(body: hash_including('symbol' => 'BTCUSDT', 'side' => 'BUY', 'type' => 'MARKET',
                                   'quantity' => '0.001', 'timestamp' => '1'))
        .to_return(status: 200, body: { 'orderId' => 42 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      allow(api.clock).to receive(:timestamp).and_return(1)
      result = api.request(:post_api_v3_order, symbol: 'BTCUSDT', side: 'BUY', type: 'MARKET', quantity: 0.001)
      expect(result['orderId']).to eq(42)
    end

    it 'raises ApiError when Binance reports a code' do
      stub_request(:get, "#{base_url}/api/v3/time")
        .to_return(status: 400, body: { 'code' => -1000, 'msg' => 'An unknown error occurred' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { api.request(:get_api_v3_time) }.to raise_error(Binance::ApiError, /unknown error/i)
    end

    it 'raises ArgumentError for unknown actions' do
      expect { api.request(:get_nope) }.to raise_error(ArgumentError, /Unknown endpoint/)
    end

    it 'uses query encoding for user stream listen keys' do
      stub_request(:post, 'https://fapi.binance.com/fapi/v1/listenKey')
        .to_return(status: 200, body: { 'listenKey' => 'abc' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      futures = described_class.new(product: :um_futures, api_key: 'k', secret_key: 's')
      expect(futures.request(:post_fapi_v1_listenkey)['listenKey']).to eq('abc')
    end

    it 'routes to the testnet host when testnet: true' do
      stub_request(:get, 'https://testnet.binance.vision/api/v3/time')
        .to_return(status: 200, body: { 'serverTime' => 123 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      testnet_api = described_class.new(product: :spot, testnet: true)
      expect(testnet_api.request(:get_api_v3_time)['serverTime']).to eq(123)
    end

    it 'falls back to production, with a warning, for products with no testnet host' do
      stub_request(:get, 'https://api.binance.com/sapi/v1/system/status')
        .to_return(status: 200, body: { 'status' => 0 }.to_json, headers: { 'Content-Type' => 'application/json' })

      wallet_testnet = described_class.new(product: :wallet, testnet: true)
      expect(wallet_testnet.logger).to receive(:warn).with(/no known testnet host/)
      expect(wallet_testnet.request(:get_sapi_v1_system_status)['status']).to eq(0)
    end
  end

  describe '#execute' do
    it 'performs a raw signed request' do
      stub_request(:get, "#{base_url}/api/v3/account")
        .with(query: hash_including('timestamp' => '1', 'signature' => /[0-9a-f]{64}/))
        .to_return(status: 200, body: { 'balances' => [] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      allow(api.clock).to receive(:timestamp).and_return(1)
      result = api.execute(:get, '/api/v3/account', {}, signed: true)
      expect(result).to eq('balances' => [])
    end
  end

  describe '#get/#post' do
    it 'wraps execute with convenience methods' do
      stub_request(:get, "#{base_url}/api/v3/ping").to_return(status: 200, body: '{}',
                                                              headers: { 'Content-Type' => 'application/json' })

      expect(api.get('/api/v3/ping')).to eq({})
    end
  end

  describe '#sync_time!' do
    it 'updates the clock from the product time endpoint' do
      stub_request(:get, "#{base_url}/api/v3/time").to_return(status: 200, body: { 'serverTime' => 123 }.to_json,
                                                              headers: { 'Content-Type' => 'application/json' })

      expect(api.sync_time!).to eq(123)
    end

    it 'falls back to local time for products without a time endpoint' do
      kyc = described_class.new(product: :kyc, api_key: 'k', secret_key: 's')
      expect(kyc.sync_time!).to be_nil
    end
  end

  describe '#authenticated?' do
    it 'requires both keys' do
      expect(described_class.new(product: :spot, api_key: 'k', secret_key: 's').authenticated?).to be(true)
      expect(described_class.new(product: :spot, api_key: 'k', secret_key: nil).authenticated?).to be(false)
      expect(described_class.new(product: :spot).authenticated?).to be(false)
    end
  end
end
