# frozen_string_literal: true

require "spec_helper"

RSpec.describe BinanceUSDM::Resources::Market do
  include_context "with binance client"
  
  let(:market) { BinanceUSDM::Resources::Market.new(client) }
  let(:base_url) { BinanceUSDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe "#ticker_24h" do
    context "when symbol is provided" do
      it "returns a Ticker model for the symbol" do
        stub_request(:get, /#{base_url}\/fapi\/v1\/ticker\/24hr\?.*symbol=BTCUSDT/)
          .to_return(
            status: 200,
            body: { "symbol" => "BTCUSDT", "lastPrice" => "50000.00", "priceChange" => "100.00" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = market.ticker_24h(symbol: "BTCUSDT")
        expect(result).to be_a(BinanceUSDM::Models::Ticker)
        expect(result.symbol).to eq("BTCUSDT")
        expect(result.last_price).to eq("50000.00")
      end
    end

    context "when no symbol is provided" do
      it "returns an array of Ticker models" do
        stub_request(:get, /#{base_url}\/fapi\/v1\/ticker\/24hr/)
          .to_return(
            status: 200,
            body: [{ "symbol" => "BTCUSDT", "lastPrice" => "50000.00" }].to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = market.ticker_24h
        expect(result).to be_an(Array)
        expect(result.first).to be_a(BinanceUSDM::Models::Ticker)
      end
    end
  end

  describe "#prices" do
    context "when symbol is provided" do
      it "returns price for the symbol" do
        stub_request(:get, /#{base_url}\/fapi\/v1\/ticker\/price\?.*symbol=BTCUSDT/)
          .to_return(
            status: 200,
            body: { "symbol" => "BTCUSDT", "price" => "50000.00" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = market.prices(symbol: "BTCUSDT")
        expect(result).to be_a(Hash)
        expect(result["symbol"]).to eq("BTCUSDT")
        expect(result["price"]).to eq("50000.00")
      end
    end

    context "when no symbol is provided" do
      it "returns prices for all symbols" do
        stub_request(:get, /#{base_url}\/fapi\/v1\/ticker\/price/)
          .to_return(
            status: 200,
            body: [{ "symbol" => "BTCUSDT", "price" => "50000.00" }].to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = market.prices
        expect(result).to be_an(Array)
        expect(result.first["symbol"]).to eq("BTCUSDT")
      end
    end
  end

  describe "#depth" do
    it "returns order book depth" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/depth/)
        .to_return(
          status: 200,
          body: { "lastUpdateId" => 12345, "bids" => [["50000.00", "1.0"]], "asks" => [["50001.00", "2.0"]] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.depth(symbol: "BTCUSDT", limit: 100)
      expect(result).to be_a(Hash)
      expect(result["bids"]).to be_an(Array)
      expect(result["asks"]).to be_an(Array)
    end
  end

  describe "#trades" do
    it "returns recent trades" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/trades/)
        .to_return(
          status: 200,
          body: [{ "id" => 1, "price" => "50000.00", "qty" => "0.5" }].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.trades(symbol: "BTCUSDT", limit: 10)
      expect(result).to be_an(Array)
      expect(result.first["id"]).to eq(1)
    end
  end

  describe "#klines" do
    it "returns kline/candlestick data" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/klines/)
        .to_return(
          status: 200,
          body: [[1699000000000, "50000.00", "50500.00", "49900.00", "50200.00", "100.0"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.klines(symbol: "BTCUSDT", interval: "1h", limit: 5)
      expect(result).to be_an(Array)
      expect(result.first).to be_an(Array)
      expect(result.first.length).to be >= 6
    end
  end

  describe "#avg_price" do
    it "returns average price for symbol" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/avgPrice/)
        .to_return(
          status: 200,
          body: { "symbol" => "BTCUSDT", "price" => "50000.00", "mins" => 5 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.avg_price(symbol: "BTCUSDT")
      expect(result["symbol"]).to eq("BTCUSDT")
      expect(result["price"]).to eq("50000.00")
      expect(result["mins"]).to eq(5)
    end
  end

  describe "#exchange_info" do
    it "returns exchange information" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/exchangeInfo/)
        .to_return(
          status: 200,
          body: {
            "timezone" => "UTC",
            "serverTime" => 1699000000000,
            "symbols" => [{ "symbol" => "BTCUSDT", "status" => "TRADING" }]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.exchange_info
      expect(result["timezone"]).to eq("UTC")
      expect(result["symbols"]).to be_an(Array)
    end
  end

  describe "#instruments" do
    it "returns list of instruments from exchange_info" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/exchangeInfo/)
        .to_return(
          status: 200,
          body: { "symbols" => [{ "symbol" => "BTCUSDT", "status" => "TRADING" }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.instruments
      expect(result).to be_an(Array)
      expect(result.first["symbol"]).to eq("BTCUSDT")
    end
  end

  describe "#open_interest" do
    it "returns open interest for symbol" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/openInterest/)
        .to_return(
          status: 200,
          body: { "symbol" => "BTCUSDT", "openInterest" => "1000.00" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.open_interest(symbol: "BTCUSDT")
      expect(result["symbol"]).to eq("BTCUSDT")
      expect(result["openInterest"]).to eq("1000.00")
    end
  end

  describe "#funding_rate_history" do
    it "returns funding rate history" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/fundingRate/)
        .to_return(
          status: 200,
          body: [{ "symbol" => "BTCUSDT", "fundingRate" => "0.0001", "fundingTime" => 1699000000000 }].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = market.funding_rate_history(symbol: "BTCUSDT", limit: 5)
      expect(result).to be_an(Array)
      expect(result.first["fundingRate"]).to eq("0.0001")
    end
  end

  describe "class methods" do
    it "fetches price via ActiveRecord-style class method" do
      stub_request(:get, /#{base_url}\/fapi\/v1\/ticker\/price\?.*symbol=BTCUSDT/)
        .to_return(
          status: 200,
          body: { "symbol" => "BTCUSDT", "price" => "50000.00" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      BinanceUSDM::Resources::Market.using(client) do
        price = BinanceUSDM::Resources::Market.price(symbol: "BTCUSDT")
        expect(price).to eq("50000.00")
      end
    end
  end
end
