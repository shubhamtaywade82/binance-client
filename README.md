# BinanceUSDM - Ruby SDK for Binance USD-M Futures

[![Gem Version](https://badge.fury.io/rb/binance_usdm.svg)](https://rubygems.org/gems/binance_usdm)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)

**BinanceUSDM** is a production-grade Ruby SDK for the Binance USD-M Futures API. Build algorithmic trading systems, market data pipelines, and portfolio management tools with clean Ruby abstractions, typed models, and resilient WebSocket streaming.

## Features

- **Typed models** for orders, positions, account info, balances, and market data
- **WebSocket market feed** with auto-reconnect and exponential backoff
- **REST API** for orders, positions, account management, and market data
- **HMAC SHA256 signing** for authenticated requests
- **Testnet support** for safe testing
- **Comprehensive market data** including klines, tickers, order book, trades, funding rates, and more
- **Clean Ruby API** - no manual JSON parsing or HTTP handling

## Installation

```ruby
# Gemfile
gem 'binance_usdm'
```

```bash
bundle install
# or
gem install binance_usdm
```

## Quick Start

```ruby
require 'binance_usdm'

# Configure with your credentials
BinanceUSDM.configure do |config|
  config.api_key = ENV['BINANCE_API_KEY']
  config.secret_key = ENV['BINANCE_SECRET_KEY']
  config.testnet = true  # Use testnet for testing
end

# Create client
client = BinanceUSDM.client

# Get account info
account = client.account_info
puts "Available Balance: #{account.available_balance}"

# Get positions
positions = client.positions
positions.each do |pos|
  puts "#{pos.symbol}: #{pos.position_amt} @ #{pos.entry_price}"
end

# Place an order
order = client.place_order(
  symbol: 'BTCUSDT',
  side: 'BUY',
  type: 'LIMIT',
  quantity: '0.001',
  price: '50000',
  time_in_force: 'GTC'
)
puts "Order placed: #{order.order_id}"
```

## Usage Examples

### Orders

```ruby
# Place a market order
order = client.place_order(
  symbol: 'ETHUSDT',
  side: 'SELL',
  type: 'MARKET',
  quantity: '0.1'
)

# Cancel an order
client.cancel_order(symbol: 'BTCUSDT', order_id: order.order_id)

# Get open orders
orders = client.open_orders(symbol: 'BTCUSDT')
```

### Account Management

```ruby
# Get account information
account = client.account_info
puts "Total Wallet Balance: #{account.total_wallet_balance}"

# Get positions
positions = client.positions(symbol: 'BTCUSDT')

# Change leverage
client.account.change_leverage(symbol: 'BTCUSDT', leverage: 20)
```

### Market Data

```ruby
# Get 24hr ticker
ticker = client.ticker(symbol: 'BTCUSDT')

# Get klines/candlesticks
klines = client.klines(symbol: 'BTCUSDT', interval: '1h', limit: 100)
```

### WebSocket Market Data

```ruby
ws = BinanceUSDM::WebSocket::MarketClient.new(testnet: true)

# Subscribe to ticker updates
ws.subscribe_ticker('BTCUSDT', 'ETHUSDT')

# Set up callbacks
ws.on_ticker = lambda do |data|
  puts "Ticker: #{data['s']} Last: #{data['c']}"
end

# Connect
ws.connect
```

## Error Handling

```ruby
begin
  client = BinanceUSDM.client
  order = client.place_order(...)
rescue BinanceUSDM::AuthenticationError => e
  puts "Invalid API credentials: #{e.message}"
rescue BinanceUSDM::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue BinanceUSDM::ApiError => e
  puts "API error #{e.code}: #{e.message}"
end
```

## Testnet

Use Binance testnet for safe testing:

```ruby
BinanceUSDM.configure do |config|
  config.api_key = 'your_testnet_api_key'
  config.secret_key = 'your_testnet_secret_key'
  config.testnet = true
end
```

Get testnet API keys at: https://testnet.binancefuture.com

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Released under the MIT License. See [LICENSE.txt](LICENSE.txt) for details.

## Disclaimer

This library is provided as-is for educational and informational purposes. Trading cryptocurrency futures involves substantial risk of loss. Always test thoroughly on testnet before using with real funds.
