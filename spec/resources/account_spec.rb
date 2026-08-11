# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BinanceUSDM::Resources::Account do
  include_context 'with binance client'

  let(:account) { BinanceUSDM::Resources::Account.new(client) }
  let(:base_url) { BinanceUSDM::Constants::Urls::TESTNET_REST_API_BASE }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#info' do
    it 'returns account information' do
      stub_request(:get, %r{#{base_url}/fapi/v2/account})
        .to_return(
          status: 200,
          body: {
            'availableBalance' => '10000.00',
            'totalWalletBalance' => '10500.00',
            'totalUnrealizedProfit' => '500.00',
            'totalMarginBalance' => '11000.00',
            'totalPositionInitialMargin' => '2200.00'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.info
      expect(result).to be_a(BinanceUSDM::Models::Account)
      expect(result.available_balance).to eq('10000.00')
      expect(result.total_wallet_balance).to eq('10500.00')
      expect(result.equity).to eq('11000.0')
      expect(result.margin_ratio).to eq('20.0')
    end
  end

  describe '#balance' do
    it 'returns account balances' do
      stub_request(:get, %r{#{base_url}/fapi/v2/balance})
        .to_return(
          status: 200,
          body: [{ 'asset' => 'USDT', 'walletBalance' => '10000.00', 'availableBalance' => '9500.00' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.balance
      expect(result).to be_an(Array)
      expect(result.first).to be_a(BinanceUSDM::Models::Balance)
      expect(result.first.asset).to eq('USDT')
      expect(result.first.wallet_balance).to eq('10000.00')
    end
  end

  describe '#positions' do
    it 'returns positions' do
      stub_request(:get, %r{#{base_url}/fapi/v2/positionRisk})
        .to_return(
          status: 200,
          body: [{ 'symbol' => 'BTCUSDT', 'positionAmt' => '0.5', 'entryPrice' => '50000.00',
                   'leverage' => '10' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.positions(symbol: 'BTCUSDT')
      expect(result).to be_an(Array)
      expect(result.first).to be_a(BinanceUSDM::Models::Position)
      expect(result.first.symbol).to eq('BTCUSDT')
      expect(result.first.leverage).to eq(10)
    end
  end

  describe '#position_mode' do
    it 'returns current position mode' do
      stub_request(:get, %r{#{base_url}/fapi/v1/positionSide/dual})
        .to_return(status: 200, body: { 'dualSidePosition' => true }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = account.position_mode
      expect(result).to eq({ 'dualSidePosition' => true })
    end
  end

  describe '#change_position_mode' do
    it 'changes position mode' do
      stub_request(:post, %r{#{base_url}/fapi/v1/positionSide/dual})
        .to_return(status: 200, body: { 'code' => 200,
                                        'msg' => 'success' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = account.change_position_mode(dual_side_position: true)
      expect(result['code']).to eq(200)
    end
  end

  describe '#change_leverage' do
    it 'changes leverage for a symbol' do
      stub_request(:post, %r{#{base_url}/fapi/v1/leverage})
        .to_return(
          status: 200,
          body: { 'leverage' => 20, 'maxNotionalValue' => '1000000', 'symbol' => 'BTCUSDT' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.change_leverage(symbol: 'BTCUSDT', leverage: 20)
      expect(result['leverage']).to eq(20)
      expect(result['symbol']).to eq('BTCUSDT')
    end
  end

  describe '#change_margin_mode' do
    it 'changes margin mode for a symbol' do
      stub_request(:post, %r{#{base_url}/fapi/v1/marginType})
        .to_return(status: 200, body: { 'code' => 200,
                                        'msg' => 'success' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = account.change_margin_mode(symbol: 'BTCUSDT', margin_mode: 'ISOLATED')
      expect(result['msg']).to eq('success')
    end
  end

  describe '#modify_position_margin' do
    it 'modifies isolated position margin' do
      stub_request(:post, %r{#{base_url}/fapi/v1/positionMargin})
        .to_return(status: 200, body: { 'amount' => '100',
                                        'type' => 1 }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = account.modify_position_margin(symbol: 'BTCUSDT', amount: '100', type: 1)
      expect(result['amount']).to eq('100')
    end
  end

  describe '#position_margin_history' do
    it 'returns position margin change history' do
      stub_request(:get, %r{#{base_url}/fapi/v1/positionMargin/history})
        .to_return(status: 200, body: [{ 'symbol' => 'BTCUSDT', 'amount' => '100',
                                         'type' => 1 }].to_json, headers: { 'Content-Type' => 'application/json' })

      result = account.position_margin_history(symbol: 'BTCUSDT')
      expect(result).to be_an(Array)
      expect(result.first['symbol']).to eq('BTCUSDT')
    end
  end

  describe '#income_history' do
    it 'returns income history' do
      stub_request(:get, %r{#{base_url}/fapi/v1/income})
        .to_return(
          status: 200,
          body: [{ 'symbol' => 'BTCUSDT', 'incomeType' => 'COMMISSION', 'income' => '-0.05' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.income_history(symbol: 'BTCUSDT')
      expect(result).to be_an(Array)
      expect(result.first['incomeType']).to eq('COMMISSION')
    end
  end

  describe '#commission_rate' do
    it 'returns commission rate for symbol' do
      stub_request(:get, %r{#{base_url}/fapi/v1/commissionRate})
        .to_return(
          status: 200,
          body: { 'symbol' => 'BTCUSDT', 'makerCommissionRate' => '0.0002', 'takerCommissionRate' => '0.0004' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = account.commission_rate(symbol: 'BTCUSDT')
      expect(result['symbol']).to eq('BTCUSDT')
      expect(result['makerCommissionRate']).to eq('0.0002')
    end
  end

  describe 'listenKey management' do
    it 'creates, keeps alive, and closes listenKey' do
      stub_request(:post, %r{#{base_url}/fapi/v1/listenKey})
        .to_return(status: 200, body: { 'listenKey' => 'test_key_123' }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:put, %r{#{base_url}/fapi/v1/listenKey})
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, %r{#{base_url}/fapi/v1/listenKey})
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      create_res = account.create_listen_key
      expect(create_res['listenKey']).to eq('test_key_123')

      expect(account.keep_alive_listen_key('test_key_123')).to eq({})
      expect(account.close_listen_key('test_key_123')).to eq({})
    end
  end

  describe 'class methods' do
    it 'delegates info and balance using scoped client' do
      stub_request(:get, %r{#{base_url}/fapi/v2/account})
        .to_return(status: 200, body: { 'availableBalance' => '5000.00' }.to_json, headers: { 'Content-Type' => 'application/json' })

      BinanceUSDM::Resources::Account.using(client) do
        res = BinanceUSDM::Resources::Account.info
        expect(res.available_balance).to eq('5000.00')
      end
    end
  end
end
