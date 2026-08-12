# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Spot::Client do
  let(:client) { described_class.new(api_key: 'k', secret_key: 's', testnet: true) }
  let(:base_url) { 'https://testnet.binance.vision' }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(client.api.clock).to receive(:sync_needed?).and_return(false)
  end

  it 'exposes typed resources' do
    expect(client.order).to be_a(Binance::Spot::Resources::Order)
    expect(client.account).to be_a(Binance::Spot::Resources::Account)
    expect(client.market).to be_a(Binance::Spot::Resources::Market)
  end

  it 'routes through the testnet host' do
    stub_request(:get, "#{base_url}/api/v3/ping").to_return(status: 200, body: '{}',
                                                            headers: { 'Content-Type' => 'application/json' })

    expect(client.market.ping).to eq({})
  end

  it 'reports authenticated? based on credentials' do
    expect(client.authenticated?).to be(true)
    expect(described_class.new.authenticated?).to be(false)
  end
end
