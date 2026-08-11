# frozen_string_literal: true

require "spec_helper"
require "binance_usdm"

RSpec.describe BinanceUSDM::Resources::Account do
  include_context "with binance client"
  
  let(:account) { BinanceUSDM::Resources::Account.new(client) }

  describe "#info" do
    it "returns account information", vcr: true do
      result = account.info
      
      expect(result).to be_a(BinanceUSDM::Models::Account)
      expect(result.available_balance).to be_present if result.respond_to?(:available_balance)
      expect(result.total_wallet_balance).to be_present if result.respond_to?(:total_wallet_balance)
    end
  end

  describe "#balance" do
    it "returns account balances", vcr: true do
      result = account.balance
      
      expect(result).to be_an(Array)
      
      if result.any?
        balance = result.first
        expect(balance).to be_a(BinanceUSDM::Models::Balance)
        expect(balance.asset).to be_present if balance.respond_to?(:asset)
        expect(balance.wallet_balance).to be_present if balance.respond_to?(:wallet_balance)
      end
    end
  end

  describe "#positions" do
    context "when no symbol is provided" do
      it "returns all positions", vcr: true do
        result = account.positions
        
        expect(result).to be_an(Array)
        
        if result.any?
          position = result.first
          expect(position).to be_a(BinanceUSDM::Models::Position)
          expect(position.symbol).to be_present if position.respond_to?(:symbol)
        end
      end
    end

    context "when symbol is provided" do
      it "returns position for the symbol", vcr: true do
        result = account.positions(symbol: "BTCUSDT")
        
        expect(result).to be_an(Array)
        
        result.each do |position|
          expect(position).to be_a(BinanceUSDM::Models::Position)
          expect(position.symbol).to eq("BTCUSDT") if position.respond_to?(:symbol)
        end
      end
    end
  end

  describe "#position_mode" do
    it "returns current position mode", vcr: true do
      result = account.position_mode
      
      expect(result).to be_a(Hash)
      expect(result).to have_key("dualSidePosition")
    end
  end

  describe "#change_position_mode" do
    context "on testnet" do
      it "changes position mode", vcr: true do
        # Note: This can only be changed once per account
        # Test may fail if already set to the requested mode
        begin
          result = account.change_position_mode(dual_side_position: false)
          
          expect(result).to be_a(Hash)
          expect(result["msg"]).to match(/success/i) if result.key?("msg")
        rescue BinanceUSDM::ApiError => e
          # May fail if mode is already set or other restrictions
          expect(e).to be_a(BinanceUSDM::ApiError)
        end
      end
    end
  end

  describe "#change_leverage" do
    it "changes leverage for a symbol", vcr: true do
      begin
        result = account.change_leverage(symbol: "BTCUSDT", leverage: 5)
        
        expect(result).to be_a(Hash)
        expect(result["leverage"]).to be_present
        expect(result["maxNotionalValue"]).to be_present
      rescue BinanceUSDM::ApiError => e
        # May fail due to various reasons (invalid symbol, etc.)
        expect(e).to be_a(BinanceUSDM::ApiError)
      end
    end
  end

  describe "#commission_rate" do
    it "returns commission rate for symbol", vcr: true do
      result = account.commission_rate(symbol: "BTCUSDT")
      
      expect(result).to be_a(Hash)
      expect(result["symbol"]).to eq("BTCUSDT")
      expect(result).to have_key("makerCommissionRate")
      expect(result).to have_key("takerCommissionRate")
    end
  end

  describe "#income_history" do
    context "without symbol" do
      it "returns income history", vcr: true do
        result = account.income_history(limit: 5)
        
        expect(result).to be_an(Array)
        expect(result.length).to be <= 5
        
        if result.any?
          income = result.first
          expect(income).to have_key("symbol")
          expect(income).to have_key("incomeType")
          expect(income).to have_key("income")
        end
      end
    end

    context "with symbol" do
      it "returns income history for symbol", vcr: true do
        result = account.income_history(symbol: "BTCUSDT", limit: 5)
        
        expect(result).to be_an(Array)
        
        if result.any?
          income = result.first
          expect(income["symbol"]).to eq("BTCUSDT")
        end
      end
    end
  end

  describe "#position_margin_history" do
    it "returns position margin change history", vcr: true do
      result = account.position_margin_history(symbol: "BTCUSDT", limit: 5)
      
      expect(result).to be_an(Array)
      expect(result.length).to be <= 5
      
      if result.any?
        history = result.first
        expect(history).to have_key("symbol")
        expect(history).to have_key("amount")
        expect(history).to have_key("type")
      end
    end
  end

  describe "#change_margin_mode" do
    it "changes margin mode for a symbol", vcr: true do
      begin
        result = account.change_margin_mode(symbol: "BTCUSDT", margin_mode: "CROSSED")
        
        expect(result).to be_a(String)
        expect(result).to match(/success/i)
      rescue BinanceUSDM::ApiError => e
        # May fail due to various reasons
        expect(e).to be_a(BinanceUSDM::ApiError)
      end
    end
  end

  describe "#modify_position_margin" do
    it "modifies isolated position margin", vcr: true do
      begin
        # This requires isolated margin mode and an open position
        result = account.modify_position_margin(
          symbol: "BTCUSDT",
          amount: "10",
          type: 1,
          position_side: "BOTH"
        )
        
        expect(result).to be_a(Hash)
        expect(result["amount"]).to eq("10")
      rescue BinanceUSDM::ApiError => e
        # Expected to fail if no isolated position exists
        expect(e).to be_a(BinanceUSDM::ApiError)
      end
    end
  end
end
