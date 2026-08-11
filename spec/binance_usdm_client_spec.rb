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

RSpec.describe BinanceUSDM::API do
  include_context "with binance client"

  describe "initialization and resource access" do
    it "exposes order, account, market, and algo_orders resources" do
      expect(api.order).to be_a(BinanceUSDM::Resources::Order)
      expect(api.account).to be_a(BinanceUSDM::Resources::Account)
      expect(api.market).to be_a(BinanceUSDM::Resources::Market)
      expect(api.algo_orders).to be_a(BinanceUSDM::Resources::AlgoOrder)
    end

    it "delegates convenience methods to resources" do
      allow(api.account).to receive(:info).and_return("account_info")
      allow(api.account).to receive(:positions).with(symbol: "BTCUSDT").and_return(["pos"])
      allow(api.market).to receive(:ticker_24h).with(symbol: "BTCUSDT").and_return("ticker")

      expect(api.account_info).to eq("account_info")
      expect(api.positions(symbol: "BTCUSDT")).to eq(["pos"])
      expect(api.ticker(symbol: "BTCUSDT")).to eq("ticker")
    end
  end

  describe "BinanceUSDM.configure" do
    it "allows global configuration" do
      BinanceUSDM.configure do |config|
        config.api_key = "config_api_key"
        config.secret_key = "config_secret_key"
        config.testnet = true
      end

      client = BinanceUSDM.client
      expect(client.client.api_key).to eq("config_api_key")
      expect(client.client.testnet).to be(true)
    end
  end

  describe "BinanceUSDM.using" do
    it "executes block in scoped context" do
      scoped_client = BinanceUSDM.client(api_key: "scoped_key", secret_key: "scoped_secret", testnet: true)
      
      BinanceUSDM.using(scoped_client) do
        expect(Thread.current[:binance_usdm_client]).to eq(scoped_client)
      end
      
      expect(Thread.current[:binance_usdm_client]).to be_nil
    end
  end
end

RSpec.describe Binance::Client do
  describe "#um_futures" do
    it "instantiates and returns a BinanceUSDM API client" do
      unified_client = Binance.client(api_key: "api_key", secret_key: "secret_key", testnet: true)
      expect(unified_client.authenticated?).to be(true)
      expect(unified_client.um_futures).to be_a(BinanceUSDM::API)
      expect(unified_client.um_futures.client.api_key).to eq("api_key")
    end

    it "raises NotImplementedError for unreleased submodules" do
      unified_client = Binance.client(api_key: "api_key", secret_key: "secret_key")
      expect { unified_client.spot }.to raise_error(NotImplementedError, /Spot client is planned/)
      expect { unified_client.cm_futures }.to raise_error(NotImplementedError, /COIN-M Futures client is planned/)
    end
  end
end
