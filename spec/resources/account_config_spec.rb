# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::AccountConfig do
  include_context 'with binance client'

  let(:account_config) { Binance::USDM::Resources::AccountConfig.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#account' do
    it 'hits the v3 account endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v3/account})
        .to_return(status: 200, body: { 'totalWalletBalance' => '100' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(account_config.account['totalWalletBalance']).to eq('100')
    end
  end

  describe '#set_fee_burn' do
    it 'hits the feeBurn endpoint with the correct payload' do
      stub_request(:post, %r{#{base_url}/fapi/v1/feeBurn})
        .with(body: hash_including('feeBurn' => 'true'))
        .to_return(status: 200, body: { 'code' => 200 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(account_config.set_fee_burn(enabled: true)['code']).to eq(200)
    end
  end

  describe '#set_multi_assets_margin' do
    it 'hits the multiAssetsMargin endpoint with the correct payload' do
      stub_request(:post, %r{#{base_url}/fapi/v1/multiAssetsMargin})
        .with(body: hash_including('multiAssetsMargin' => 'false'))
        .to_return(status: 200, body: { 'code' => 200 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(account_config.set_multi_assets_margin(enabled: false)['code']).to eq(200)
    end
  end

  describe '#pm_account_info' do
    it 'hits the pmAccountInfo endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/pmAccountInfo})
        .to_return(status: 200, body: { 'asset' => 'USDT' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(account_config.pm_account_info(asset: 'USDT')['asset']).to eq('USDT')
    end
  end
end
