# frozen_string_literal: true

require "spec_helper"
require "binance_usdm"
require "vcr"
require "webmock/rspec"

RSpec.shared_context "with binance client" do
  let(:api_key) { ENV.fetch("BINANCE_API_KEY", "test_api_key") }
  let(:secret_key) { ENV.fetch("BINANCE_SECRET_KEY", "test_secret_key") }
  let(:testnet) { true }
  let(:client) { BinanceUSDM::Client.new(api_key: api_key, secret_key: secret_key, testnet: testnet) }
  let(:api) { BinanceUSDM.client(api_key: api_key, secret_key: secret_key, testnet: testnet) }
end

RSpec.shared_context "with vcr cassette" do
  around(:each) do |example|
    cassette_name = example.full_description.gsub(/[^a-zA-Z0-9_]+/, "_").gsub(/^_+|_+$/, "")
    VCR.use_cassette(cassette_name, record: :once) do
      example.run
    end
  end
end
