# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Binance::USDM::Resources::Export do
  include_context 'with binance client'

  let(:export) { Binance::USDM::Resources::Export.new(client) }
  let(:base_url) { Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#request_order_download' do
    it 'hits the order/asyn endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/order/asyn})
        .to_return(status: 200, body: { 'downloadId' => 'abc' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = export.request_order_download(start_time: 1, end_time: 2)
      expect(result['downloadId']).to eq('abc')
    end
  end

  describe '#order_download_link' do
    it 'hits the order/asyn/id endpoint' do
      stub_request(:get, %r{#{base_url}/fapi/v1/order/asyn/id})
        .to_return(status: 200, body: { 'status' => 'completed' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = export.order_download_link(download_id: 'abc')
      expect(result['status']).to eq('completed')
    end
  end
end
