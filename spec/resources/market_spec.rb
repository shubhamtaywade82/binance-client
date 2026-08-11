# frozen_string_literal: true

require "spec_helper"
require "binance_usdm"

RSpec.describe BinanceUSDM::Resources::Market do
  include_context "with binance client"
  
  let(:market) { BinanceUSDM::Resources::Market.new(client) }

  describe "#ticker_24h" do
    context "when symbol is provided" do
      it "returns a Ticker model for the symbol", vcr: true do
        result = market.ticker_24h(symbol: "BTCUSDT")
        
        expect(result).to be_a(BinanceUSDM::Models::Ticker)
        expect(result.symbol).to eq("BTCUSDT") if result.respond_to?(:symbol)
      end
    end

    context "when no symbol is provided" do
      it "returns an array of Ticker models", vcr: true do
        result = market.ticker_24h
        
        expect(result).to be_an(Array)
        expect(result.first).to be_a(BinanceUSDM::Models::Ticker) if result.any?
      end
    end
  end

  describe "#prices" do
    context "when symbol is provided" do
      it "returns price for the symbol", vcr: true do
        result = market.prices(symbol: "BTCUSDT")
        
        expect(result).to be_a(Hash)
        expect(result["symbol"]).to eq("BTCUSDT")
        expect(result["price"]).to match(/^\d+\.?\d*$/)
      end
    end

    context "when no symbol is provided" do
      it "returns prices for all symbols", vcr: true do
        result = market.prices
        
        expect(result).to be_an(Array)
        expect(result.first).to be_a(Hash)
        expect(result.first).to have_key("symbol")
        expect(result.first).to have_key("price")
      end
    end
  end

  describe "#depth" do
    it "returns order book depth", vcr: true do
      result = market.depth(symbol: "BTCUSDT", limit: 100)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key("lastUpdateId")
      expect(result).to have_key("bids")
      expect(result).to have_key("asks")
      expect(result["bids"]).to be_an(Array)
      expect(result["asks"]).to be_an(Array)
    end
  end

  describe "#trades" do
    it "returns recent trades", vcr: true do
      result = market.trades(symbol: "BTCUSDT", limit: 10)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 10
      
      if result.any?
        trade = result.first
        expect(trade).to have_key("id")
        expect(trade).to have_key("price")
        expect(trade).to have_key("qty")
      end
    end
  end

  describe "#klines" do
    it "returns kline/candlestick data", vcr: true do
      result = market.klines(symbol: "BTCUSDT", interval: "1h", limit: 5)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 5
      
      if result.any?
        kline = result.first
        # Klines are arrays: [open_time, open, high, low, close, volume, ...]
        expect(kline).to be_an(Array)
        expect(kline.length).to be >= 6
      end
    end
  end

  describe "#avg_price" do
    it "returns average price for symbol", vcr: true do
      result = market.avg_price(symbol: "BTCUSDT")
      
      expect(result).to be_a(Hash)
      expect(result["symbol"]).to eq("BTCUSDT")
      expect(result["mins"]).to be_a(Integer)
      expect(result["price"]).to match(/^\d+\.?\d*$/)
    end
  end

  describe "#exchange_info" do
    it "returns exchange information", vcr: true do
      result = market.exchange_info
      
      expect(result).to be_a(Hash)
      expect(result).to have_key("timezone")
      expect(result).to have_key("serverTime")
      expect(result).to have_key("symbols")
    end
  end

  describe "#instruments" do
    it "returns list of instruments", vcr: true do
      result = market.instruments
      
      expect(result).to be_an(Array)
      
      if result.any?
        instrument = result.first
        expect(instrument).to have_key("symbol")
        expect(instrument).to have_key("status")
      end
    end
  end

  describe "#open_interest" do
    it "returns open interest for symbol", vcr: true do
      result = market.open_interest(symbol: "BTCUSDT")
      
      expect(result).to be_a(Hash)
      expect(result["symbol"]).to eq("BTCUSDT")
      expect(result["openInterest"]).to match(/^\d+\.?\d*$/)
    end
  end

  describe "#funding_rate_history" do
    it "returns funding rate history", vcr: true do
      result = market.funding_rate_history(symbol: "BTCUSDT", limit: 5)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 5
      
      if result.any?
        rate = result.first
        expect(rate).to have_key("symbol")
        expect(rate).to have_key("fundingRate")
      end
    end
  end
end
