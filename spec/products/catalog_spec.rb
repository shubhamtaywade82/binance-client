# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::Core::Catalog do
  describe 'catalog completeness' do
    it 'covers every REST family in the manifest' do
      expected = %i[
        spot um_futures cm_futures options portfolio_margin portfolio_margin_pro
        wallet margin sub_account simple_earn staking convert pay fiat c2c
        gift_card mining rebate algo crypto_loan vip_loan vip_service vip_caas
        institutional_loan discount_buy dual_investment exchange_link fund_account
        link_trade link_plus block_matching prediction stocks copy_trading alpha kyc
      ]
      expect(described_class::PRODUCTS.keys).to include(*expected)
    end

    it 'indexes 888 endpoints across 36 products' do
      expect(described_class::PRODUCTS.size).to eq(36)
      total = described_class::PRODUCTS.keys.sum { |p| described_class.for_product(p).size }
      expect(total).to eq(888)
    end

    it 'exposes every endpoint under its product' do
      described_class::ENDPOINTS.each do |product, actions|
        expect(described_class.for_product(product)).to contain_exactly(*actions)
      end
    end

    it 'generates unique action names within each product' do
      described_class::PRODUCTS.each_key do |product|
        actions = described_class.for_product(product).map { |e| e[:action] }
        expect(actions.uniq.size).to eq(actions.size)
      end
    end
  end

  describe '.find' do
    it 'resolves a known action' do
      endpoint = described_class.find(:spot, :get_api_v3_historicalblocktrades)
      expect(endpoint[:method]).to eq(:get)
      expect(endpoint[:path]).to eq('/api/v3/historicalBlockTrades')
      expect(endpoint[:security]).to eq(:market)
      expect(endpoint[:host]).to eq('https://api.binance.com')
    end

    it 'resolves host overrides for futures paths' do
      endpoint = described_class.find(:um_futures, :get_fapi_v1_time)
      expect(endpoint[:host]).to eq('https://fapi.binance.com')
    end

    it 'returns nil for unknown actions' do
      expect(described_class.find(:spot, :get_nope)).to be_nil
      expect(described_class.find(:not_a_product, :get_api_v3_time)).to be_nil
    end
  end

  describe '.exists?' do
    it 'checks action existence per product' do
      expect(described_class.exists?(:wallet, :get_sapi_v1_system_status)).to be(true)
      expect(described_class.exists?(:spot, :get_sapi_v1_system_status)).to be(false)
    end
  end

  describe '.product_metadata' do
    it 'returns host and time path' do
      meta = described_class.product_metadata(:wallet)
      expect(meta[:host]).to eq('https://api.binance.com')
      expect(meta[:time_path]).to eq('/api/v3/time')
    end

    it 'returns nil for unknown products' do
      expect(described_class.product_metadata(:bogus)).to be_nil
    end
  end
end
