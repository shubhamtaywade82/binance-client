# frozen_string_literal: true

require 'spec_helper'

# Live smoke tests against the Binance USD-M Futures testnet.
# Public market data needs no credentials; authenticated tests are skipped
# unless BINANCE_TESTNET_API_KEY and BINANCE_TESTNET_SECRET_KEY are set
# (these are wired as CI secrets in .github/workflows/live-integration.yml).
RSpec.describe 'Binance USD-M testnet e2e' do
  let(:api_key) { ENV.fetch('BINANCE_TESTNET_API_KEY', nil) }
  let(:secret_key) { ENV.fetch('BINANCE_TESTNET_SECRET_KEY', nil) }
  let(:client) do
    BinanceUSDM::Client.new(api_key: api_key || 'public', secret_key: secret_key || 'public', testnet: true)
  end

  before(:all) do
    WebMock.disable_net_connect!(allow: 'testnet.binancefuture.com')
  end

  after(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe 'market data' do
    it 'fetches the 24h ticker' do
      ticker = client.market.ticker_24h(symbol: 'BTCUSDT')
      expect(ticker).to be_a(BinanceUSDM::Models::Ticker)
      expect(ticker.symbol).to eq('BTCUSDT')
      expect(ticker.last_price.to_f).to be_positive
    end

    it 'fetches the latest price' do
      price = client.market.prices(symbol: 'BTCUSDT')
      expect(price['symbol']).to eq('BTCUSDT')
      expect(price['price'].to_f).to be_positive
    end

    it 'fetches klines' do
      klines = client.market.klines(symbol: 'BTCUSDT', interval: '1m', limit: 3)
      expect(klines.length).to eq(3)
      expect(klines.first).to be_an(Array)
    end

    it 'fetches the order book' do
      depth = client.market.depth(symbol: 'BTCUSDT', limit: 5)
      expect(depth['bids']).to be_an(Array)
      expect(depth['asks']).to be_an(Array)
      expect(depth['bids']).not_to be_empty
    end

    it 'fetches exchange info' do
      info = client.market.exchange_info
      expect(info['symbols']).to be_an(Array)
      expect(info['symbols']).not_to be_empty
    end

    it 'fetches funding rate and open interest' do
      expect(client.market.funding_rate(symbol: 'BTCUSDT')).to include('symbol' => 'BTCUSDT')
      expect(client.market.open_interest(symbol: 'BTCUSDT')).to include('symbol' => 'BTCUSDT')
    end

    it 'maps an invalid symbol to an API error' do
      expect { client.market.depth(symbol: 'NOTREAL') }
        .to raise_error(BinanceUSDM::ApiError, /Invalid symbol/i)
    end
  end

  describe 'authenticated endpoints' do
    before do
      skip 'set BINANCE_TESTNET_API_KEY and BINANCE_TESTNET_SECRET_KEY to run' unless api_key && secret_key
    end

    it 'fetches account info and balance' do
      account = client.account.info
      expect(account).to be_a(BinanceUSDM::Models::Account)
      expect(account.total_wallet_balance).to be_a(String)

      balances = client.account.balance
      expect(balances).to be_an(Array)
      expect(balances.first).to be_a(BinanceUSDM::Models::Balance)
    end

    it 'places, finds and cancels a limit order' do
      price = client.market.prices(symbol: 'BTCUSDT')['price'].to_f
      order = client.order.place(
        symbol: 'BTCUSDT', side: 'BUY', type: 'LIMIT', quantity: '0.001',
        price: (price * 0.9).round.to_s, time_in_force: 'GTC'
      )
      expect(order).to be_a(BinanceUSDM::Models::Order)
      expect(order.active?).to be(true)

      found = client.order.find(symbol: 'BTCUSDT', order_id: order.order_id)
      expect(found.order_id).to eq(order.order_id)

      canceled = client.order.cancel(symbol: 'BTCUSDT', order_id: order.order_id)
      expect(canceled.canceled?).to be(true)
    end
  end
end
