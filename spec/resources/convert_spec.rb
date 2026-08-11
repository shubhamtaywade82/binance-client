# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::Convert do
  include_context 'with binance client'

  let(:convert) { Binance::USDM::Resources::Convert.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#exchange_info' do
    it 'hits the convert/exchangeInfo endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/convert/exchangeInfo})
        .to_return(status: 200, body: [{ 'fromAsset' => 'BTC', 'toAsset' => 'USDT' }].to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = convert.exchange_info
      expect(result.first['fromAsset']).to eq('BTC')
    end
  end

  describe '#get_quote' do
    it 'raises without an amount' do
      expect do
        convert.get_quote(from_asset: 'BTC', to_asset: 'USDT')
      end.to raise_error(ArgumentError, /from_amount or to_amount/)
    end

    it 'hits the convert/getQuote endpoint' do
      stub_request(:post, %r{#{base_url}/fapi/v1/convert/getQuote})
        .to_return(status: 200, body: { 'quoteId' => 'q1' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = convert.get_quote(from_asset: 'BTC', to_asset: 'USDT', from_amount: '0.1')
      expect(result['quoteId']).to eq('q1')
    end
  end

  describe '#accept_quote' do
    it 'hits the convert/acceptQuote endpoint' do
      stub_request(:post, %r{#{base_url}/fapi/v1/convert/acceptQuote})
        .to_return(status: 200, body: { 'orderId' => 'o1' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = convert.accept_quote(quote_id: 'q1')
      expect(result['orderId']).to eq('o1')
    end
  end
end
