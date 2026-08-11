# frozen_string_literal: true

require 'spec_helper'
require 'binance_usdm'

RSpec.describe BinanceUSDM::Models do
  describe 'Order model' do
    let(:order_data) do
      {
        'orderId' => 12_345,
        'symbol' => 'BTCUSDT',
        'status' => 'NEW',
        'clientOrderId' => 'abc123',
        'price' => '50000.00',
        'avgPrice' => '0.00',
        'origQty' => '0.001',
        'executedQty' => '0.000',
        'cumQty' => '0.000',
        'cumQuote' => '0.00',
        'side' => 'BUY',
        'type' => 'LIMIT',
        'timeInForce' => 'GTC',
        'updateTime' => 1_699_000_000_000,
        'time' => 1_699_000_000_000
      }
    end

    subject(:order) { BinanceUSDM::Models::Order.new(order_data) }

    it 'initializes with order data' do
      expect(order.order_id).to eq(12_345)
      expect(order.symbol).to eq('BTCUSDT')
      expect(order.status).to eq('NEW')
      expect(order.side).to eq('BUY')
      expect(order.type).to eq('LIMIT')
    end

    describe '#active?' do
      context 'when status is NEW' do
        it 'returns true' do
          expect(order.active?).to be(true)
        end
      end

      context 'when status is FILLED' do
        let(:order_data) { super().merge('status' => 'FILLED') }

        it 'returns false' do
          expect(order.active?).to be(false)
        end
      end
    end

    describe '#status?' do
      context 'when status is FILLED' do
        let(:order_data) { super().merge('status' => 'FILLED') }

        it 'returns true' do
          expect(order.status?).to be(true)
        end
      end

      context 'when status is NEW' do
        it 'returns false' do
          expect(order.status?).to be(false)
        end
      end
    end

    describe '#partially_filled?' do
      context 'when status is PARTIALLY_FILLED' do
        let(:order_data) { super().merge('status' => 'PARTIALLY_FILLED') }

        it 'returns true' do
          expect(order.partially_filled?).to be(true)
        end
      end

      context 'when status is NEW' do
        it 'returns false' do
          expect(order.partially_filled?).to be(false)
        end
      end
    end

    describe '#canceled?' do
      context 'when status is CANCELED' do
        let(:order_data) { super().merge('status' => 'CANCELED') }

        it 'returns true' do
          expect(order.canceled?).to be(true)
        end
      end

      context 'when status is REJECTED' do
        let(:order_data) { super().merge('status' => 'REJECTED') }

        it 'returns true' do
          expect(order.canceled?).to be(true)
        end
      end

      context 'when status is NEW' do
        it 'returns false' do
          expect(order.canceled?).to be(false)
        end
      end
    end
  end

  describe 'Position model' do
    let(:position_data) do
      {
        'symbol' => 'BTCUSDT',
        'positionAmt' => '0.001',
        'entryPrice' => '50000.00',
        'markPrice' => '51000.00',
        'unrealizedProfit' => '1.00',
        'liquidationPrice' => '45000.00',
        'leverage' => '10',
        'positionSide' => 'LONG'
      }
    end

    subject(:position) { BinanceUSDM::Models::Position.new(position_data) }

    it 'initializes with position data' do
      expect(position.symbol).to eq('BTCUSDT')
      expect(position.position_amt).to eq('0.001')
      expect(position.entry_price).to eq('50000.00')
      expect(position.leverage).to eq(10)
    end

    describe '#long?' do
      context 'when position side is LONG' do
        it 'returns true' do
          expect(position.long?).to be(true)
        end
      end

      context 'when position side is SHORT' do
        let(:position_data) { super().merge('positionSide' => 'SHORT', 'positionAmt' => '-0.001') }

        it 'returns false' do
          expect(position.long?).to be(false)
        end
      end
    end

    describe '#short?' do
      context 'when position side is SHORT' do
        let(:position_data) { super().merge('positionSide' => 'SHORT', 'positionAmt' => '-0.001') }

        it 'returns true' do
          expect(position.short?).to be(true)
        end
      end

      context 'when position side is LONG' do
        it 'returns false' do
          expect(position.short?).to be(false)
        end
      end
    end

    describe '#has_position?' do
      context 'when position amount is non-zero' do
        it 'returns true' do
          expect(position.has_position?).to be(true)
        end
      end

      context 'when position amount is zero' do
        let(:position_data) { super().merge('positionAmt' => '0.000') }

        it 'returns false' do
          expect(position.has_position?).to be(false)
        end
      end
    end

    describe '#profit?' do
      context 'when unrealized profit is positive' do
        it 'returns true' do
          expect(position.profit?).to be(true)
        end
      end

      context 'when unrealized profit is negative' do
        let(:position_data) { super().merge('unrealizedProfit' => '-1.00') }

        it 'returns false' do
          expect(position.profit?).to be(false)
        end
      end
    end
  end

  describe 'Account model' do
    let(:account_data) do
      {
        'availableBalance' => '10000.00',
        'totalWalletBalance' => '10000.00',
        'totalUnrealizedProfit' => '500.00',
        'totalMarginBalance' => '10500.00',
        'totalPositionInitialMargin' => '2000.00',
        'totalOpenOrderInitialMargin' => '100.00',
        'crossWalletBalance' => '9500.00',
        'maxWithdrawAmount' => '8000.00'
      }
    end

    subject(:account) { BinanceUSDM::Models::Account.new(account_data) }

    it 'initializes with account data' do
      expect(account.available_balance).to eq('10000.00')
      expect(account.total_wallet_balance).to eq('10000.00')
      expect(account.total_unrealized_pnl).to eq('500.00')
    end

    describe '#equity' do
      it 'returns total wallet balance plus unrealized PnL' do
        expect(account.equity).to eq('10500.0')
      end
    end

    describe '#margin_ratio' do
      it 'calculates margin ratio as percentage' do
        # (2000 / 10500) * 100 = 19.05
        expect(account.margin_ratio).to eq('19.05')
      end

      context 'when total margin balance is zero' do
        let(:account_data) { super().merge('totalMarginBalance' => '0.00') }

        it 'returns 0' do
          expect(account.margin_ratio).to eq('0')
        end
      end
    end
  end

  describe 'Trade model' do
    let(:trade_data) do
      {
        'id' => 12_345,
        'orderId' => 67_890,
        'symbol' => 'BTCUSDT',
        'price' => '50000.00',
        'qty' => '0.001',
        'quoteQty' => '50.00',
        'commission' => '0.05',
        'commissionAsset' => 'USDT',
        'time' => 1_699_000_000_000,
        'buyer' => false,
        'maker' => true
      }
    end

    subject(:trade) { BinanceUSDM::Models::Trade.new(trade_data) }

    it 'initializes with trade data' do
      expect(trade.id).to eq(12_345)
      expect(trade.order_id).to eq(67_890)
      expect(trade.symbol).to eq('BTCUSDT')
      expect(trade.price).to eq('50000.00')
      expect(trade.qty).to eq('0.001')
      expect(trade.maker).to be(true)
      expect(trade.buyer).to be(false)
    end
  end

  describe 'Ticker model' do
    let(:ticker_data) do
      {
        'symbol' => 'BTCUSDT',
        'lastPrice' => '50000.00',
        'priceChange' => '1000.00',
        'priceChangePercent' => '2.00',
        'highPrice' => '51000.00',
        'lowPrice' => '49000.00',
        'volume' => '1000.00',
        'quoteVolume' => '50000000.00',
        'openPrice' => '49000.00',
        'count' => 10_000
      }
    end

    subject(:ticker) { BinanceUSDM::Models::Ticker.new(ticker_data) }

    it 'initializes with ticker data' do
      expect(ticker.symbol).to eq('BTCUSDT')
      expect(ticker.last_price).to eq('50000.00')
      expect(ticker.price_change_percent).to eq('2.00')
      expect(ticker.count).to eq(10_000)
    end
  end

  describe 'Balance model' do
    let(:balance_data) do
      {
        'asset' => 'USDT',
        'walletBalance' => '10000.00',
        'unrealizedProfit' => '500.00',
        'availableBalance' => '9500.00',
        'maxWithdrawAmount' => '9000.00'
      }
    end

    subject(:balance) { BinanceUSDM::Models::Balance.new(balance_data) }

    it 'initializes with balance data' do
      expect(balance.asset).to eq('USDT')
      expect(balance.wallet_balance).to eq('10000.00')
      expect(balance.unrealized_profit).to eq('500.00')
      expect(balance.available_balance).to eq('9500.00')
    end
  end
end
