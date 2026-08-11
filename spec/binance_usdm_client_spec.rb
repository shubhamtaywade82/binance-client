# frozen_string_literal: true

require "spec_helper"
require "binance_usdm"

RSpec.describe BinanceUSDM::Client do
  include_context "with binance client"

  describe "#initialize" do
    context "with testnet enabled" do
      it "creates a client with testnet URL" do
        expect(client.testnet).to be(true)
        expect(client.instance_variable_get(:@base_url)).to eq(BinanceUSDM::Constants::Urls::TESTNET_REST_API_BASE)
      end
    end

    context "with testnet disabled" do
      let(:testnet) { false }

      it "creates a client with production URL" do
        expect(client.testnet).to be(false)
        expect(client.instance_variable_get(:@base_url)).to eq(BinanceUSDM::Constants::Urls::REST_API_BASE)
      end
    end

    it "stores api_key and secret_key" do
      expect(client.api_key).to eq(api_key)
      expect(client.secret_key).to eq(secret_key)
    end
  end

  describe "#get" do
    context "when request is successful" do
      it "returns parsed JSON response" do
        allow(client).to receive(:request).and_return({ "symbol" => "BTCUSDT", "price" => "50000.00" })
        
        result = client.get("/fapi/v1/ticker/price", params: { symbol: "BTCUSDT" }, signed: false)
        
        expect(result).to be_a(Hash)
        expect(result["symbol"]).to eq("BTCUSDT")
      end
    end
  end

  describe "#post" do
    context "when request is successful" do
      it "returns parsed JSON response" do
        allow(client).to receive(:request).and_return({ "orderId" => 12345, "status" => "NEW" })
        
        result = client.post("/fapi/v1/order", params: { symbol: "BTCUSDT", side: "BUY", type: "LIMIT" })
        
        expect(result).to be_a(Hash)
        expect(result["orderId"]).to eq(12345)
      end
    end
  end

  describe "error handling" do
    context "when connection fails" do
      it "raises ConnectionError" do
        allow(client).to receive(:connection).and_raise(Faraday::ConnectionFailed.new("Connection refused"))
        
        expect {
          client.get("/fapi/v1/time")
        }.to raise_error(BinanceUSDM::ConnectionError, /Failed to connect/)
      end
    end

    context "when timeout occurs" do
      it "raises ConnectionError" do
        allow(client).to receive(:connection).and_raise(Faraday::TimeoutError.new("Request timeout"))
        
        expect {
          client.get("/fapi/v1/time")
        }.to raise_error(BinanceUSDM::ConnectionError, /timeout/)
      end
    end
  end
end
