# frozen_string_literal: true

require 'spec_helper'
require 'binance_usdm'

RSpec.describe Binance::USDM::Client do
  include_context 'with binance client'

  describe '#initialize' do
    context 'with testnet enabled' do
      it 'creates a client with testnet URL' do
        expect(client.testnet).to be(true)
        expect(client.instance_variable_get(:@base_url)).to eq(Binance::USDM::Constants::Urls::TESTNET_REST_API_BASE)
      end
    end

    context 'with testnet disabled' do
      let(:testnet) { false }

      it 'creates a client with production URL' do
        expect(client.testnet).to be(false)
        expect(client.instance_variable_get(:@base_url)).to eq(Binance::USDM::Constants::Urls::REST_API_BASE)
      end
    end

    it 'stores api_key and secret_key' do
      expect(client.api_key).to eq(api_key)
      expect(client.secret_key).to eq(secret_key)
    end
  end

  describe '#get' do
    context 'when request is successful' do
      it 'returns parsed JSON response' do
        allow(client).to receive(:request).and_return({ 'symbol' => 'BTCUSDT', 'price' => '50000.00' })

        result = client.get('/fapi/v1/ticker/price', params: { symbol: 'BTCUSDT' }, signed: false)

        expect(result).to be_a(Hash)
        expect(result['symbol']).to eq('BTCUSDT')
      end
    end
  end

  describe '#post' do
    context 'when request is successful' do
      it 'returns parsed JSON response' do
        allow(client).to receive(:request).and_return({ 'orderId' => 12_345, 'status' => 'NEW' })

        result = client.post('/fapi/v1/order', params: { symbol: 'BTCUSDT', side: 'BUY', type: 'LIMIT' })

        expect(result).to be_a(Hash)
        expect(result['orderId']).to eq(12_345)
      end
    end
  end

  describe 'error handling' do
    context 'when connection fails' do
      it 'raises ConnectionError' do
        allow(client).to receive(:connection).and_raise(Faraday::ConnectionFailed.new('Connection refused'))

        expect do
          client.get('/fapi/v1/time')
        end.to raise_error(Binance::USDM::ConnectionError, /Failed to connect/)
      end
    end

    context 'when timeout occurs' do
      it 'raises ConnectionError' do
        allow(client).to receive(:connection).and_raise(Faraday::TimeoutError.new('Request timeout'))

        expect do
          client.get('/fapi/v1/time')
        end.to raise_error(Binance::USDM::ConnectionError, /timeout/)
      end
    end
  end
end

RSpec.describe Binance::USDM::API do
  include_context 'with binance client'

  describe 'initialization and resource access' do
    it 'exposes order, account, market, and algo_orders resources' do
      expect(api.order).to be_a(Binance::USDM::Resources::Order)
      expect(api.account).to be_a(Binance::USDM::Resources::Account)
      expect(api.market).to be_a(Binance::USDM::Resources::Market)
      expect(api.algo_orders).to be_a(Binance::USDM::Resources::AlgoOrder)
    end

    it 'delegates convenience methods to resources' do
      allow(api.account).to receive(:info).and_return('account_info')
      allow(api.account).to receive(:positions).with(symbol: 'BTCUSDT').and_return(['pos'])
      allow(api.market).to receive(:ticker_24h).with(symbol: 'BTCUSDT').and_return('ticker')

      expect(api.account_info).to eq('account_info')
      expect(api.positions(symbol: 'BTCUSDT')).to eq(['pos'])
      expect(api.ticker(symbol: 'BTCUSDT')).to eq('ticker')
    end
  end

  describe 'Binance::USDM.configure' do
    it 'allows global configuration' do
      Binance::USDM.configure do |config|
        config.api_key = 'config_api_key'
        config.secret_key = 'config_secret_key'
        config.testnet = true
      end

      client = Binance::USDM.client
      expect(client.client.api_key).to eq('config_api_key')
      expect(client.client.testnet).to be(true)
    end
  end

  describe 'Binance::USDM.using' do
    it 'executes block in scoped context' do
      scoped_client = Binance::USDM.client(api_key: 'scoped_key', secret_key: 'scoped_secret', testnet: true)

      Binance::USDM.using(scoped_client) do
        expect(Thread.current[:binance_usdm_client]).to eq(scoped_client)
      end

      expect(Thread.current[:binance_usdm_client]).to be_nil
    end
  end
end

RSpec.describe Binance::Client do
  describe '#um_futures' do
    it 'instantiates and returns a Binance::USDM API client' do
      unified_client = Binance.client(api_key: 'api_key', secret_key: 'secret_key', testnet: true)
      expect(unified_client.authenticated?).to be(true)
      expect(unified_client.um_futures).to be_a(Binance::USDM::API)
      expect(unified_client.um_futures.client.api_key).to eq('api_key')
    end

    it 'exposes a typed Spot client alongside generic clients for other catalog products' do
      unified_client = Binance.client(api_key: 'api_key', secret_key: 'secret_key')
      expect(unified_client.spot).to be_a(Binance::Spot::Client)
      expect(unified_client.spot.api.product).to eq(:spot)
      expect(unified_client.cm_futures).to be_a(Binance::Products::API)
      expect(unified_client.cm_futures.product).to eq(:cm_futures)
      expect(unified_client.wallet).to be_a(Binance::Products::API)
      expect(unified_client.product(:margin)).to be_a(Binance::Products::API)
      expect { unified_client.product(:not_a_product) }.to raise_error(ArgumentError, /Unknown product/)
    end
  end
end

RSpec.describe Binance::USDM::SignatureHelper do
  describe '.generate_signature' do
    it 'generates valid HMAC-SHA256 signature' do
      sig = described_class.generate_signature('secret', 'symbol=BTCUSDT&timestamp=1699000000000')
      expect(sig).to be_a(String)
      expect(sig.length).to eq(64)
    end

    it 'generates valid RSA signature' do
      rsa_key = OpenSSL::PKey::RSA.generate(2048)
      sig = described_class.generate_signature(rsa_key, 'symbol=BTCUSDT&timestamp=1699000000000')
      expect(sig).to be_a(String)
      expect(Base64.decode64(sig)).not_to be_empty
    end
  end

  describe '.format_params' do
    it 'formats snake_case keys to camelCase and stringifies booleans and symbols' do
      params = { symbol: :btcusdt, dual_side_position: true, recv_window: 5000, empty_field: nil }
      formatted = described_class.format_params(params)
      expect(formatted).to eq({
                                'symbol' => 'btcusdt',
                                'dualSidePosition' => 'true',
                                'recvWindow' => 5000
                              })
    end
  end
end

RSpec.describe Binance::USDM::WebSocket::UserDataClient do
  include_context 'with binance client'

  let(:uds) { described_class.new(client: client) }

  describe 'ListenKey and event dispatching' do
    it 'dispatches ORDER_TRADE_UPDATE events to callback' do
      received_order = nil
      uds.on_order_update = ->(order) { received_order = order }

      uds.send(:on_message, {
                 'e' => 'ORDER_TRADE_UPDATE',
                 'o' => { 's' => 'BTCUSDT', 'i' => 12_345, 'X' => 'FILLED' }
               })

      expect(received_order).not_to be_nil
      expect(received_order['s']).to eq('BTCUSDT')
      expect(received_order['X']).to eq('FILLED')
    end

    it 'dispatches ACCOUNT_UPDATE events to callback' do
      received_account = nil
      uds.on_account_update = ->(account) { received_account = account }

      uds.send(:on_message, {
                 'e' => 'ACCOUNT_UPDATE',
                 'a' => { 'm' => 'ORDER', 'B' => [{ 'a' => 'USDT', 'wb' => '10000' }] }
               })

      expect(received_account['m']).to eq('ORDER')
    end
  end
end

RSpec.describe Binance::USDM::WebSocket::OrderBook do
  let(:book) { described_class.new(symbol: 'BTCUSDT') }

  describe 'L2 Order Book snapshot and sequence synchronization' do
    it 'applies snapshot and computes best_bid, best_ask, spread, mid_price' do
      snapshot = {
        'lastUpdateId' => 100,
        'bids' => [['50000.00', '1.5'], ['49900.00', '2.0']],
        'asks' => [['50100.00', '1.0'], ['50200.00', '3.0']]
      }

      book.apply_snapshot(snapshot)

      expect(book.synced?).to be(true)
      expect(book.last_update_id).to eq(100)
      expect(book.best_bid).to eq(BigDecimal('50000.00'))
      expect(book.best_ask).to eq(BigDecimal('50100.00'))
      expect(book.spread).to eq(BigDecimal('100.00'))
      expect(book.mid_price).to eq(BigDecimal('50050.00'))
    end

    it 'updates depth levels from stream and removes levels with zero quantity' do
      snapshot = {
        'lastUpdateId' => 100,
        'bids' => [['50000.00', '1.5']],
        'asks' => [['50100.00', '1.0']]
      }
      book.apply_snapshot(snapshot)

      # Process depthUpdate
      book.process_event({
                           'e' => 'depthUpdate',
                           'pu' => 100,
                           'u' => 105,
                           'b' => [['50050.00', '2.0'], ['50000.00', '0.0']], # New higher bid, old bid removed
                           'a' => [['50080.00', '0.5']] # Tighter ask
                         })

      expect(book.last_update_id).to eq(105)
      expect(book.best_bid).to eq(BigDecimal('50050.00'))
      expect(book.bids[BigDecimal('50000.00')]).to be_nil
      expect(book.best_ask).to eq(BigDecimal('50080.00'))
      expect(book.spread).to eq(BigDecimal('30.00'))
    end
  end
end
