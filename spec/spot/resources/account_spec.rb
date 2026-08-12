# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Spot::Resources::Account do
  let(:api) { Binance::Products::API.new(product: :spot, api_key: 'k', secret_key: 's') }
  let(:account) { described_class.new(api) }
  let(:base_url) { 'https://api.binance.com' }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(api.clock).to receive(:sync_needed?).and_return(false)
  end

  describe '#info' do
    it 'returns a typed Account model' do
      stub_request(:get, %r{#{base_url}/api/v3/account})
        .to_return(status: 200, body: { 'makerCommission' => 10, 'balances' => [] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = account.info
      expect(result).to be_a(Binance::Spot::Models::Account)
    end
  end

  describe '#trades' do
    it 'returns typed Trade models' do
      stub_request(:get, %r{#{base_url}/api/v3/myTrades})
        .to_return(status: 200, body: [{ 'id' => 1, 'symbol' => 'BTCUSDT', 'price' => '50000' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = account.trades(symbol: 'BTCUSDT')
      expect(result.first).to be_a(Binance::Spot::Models::Trade)
    end
  end
end
