# Binance Ruby SDK - Complete API Support

## Overview

This document describes the transformation of the `binance_usdm` gem into a **complete, unified Binance Ruby SDK** supporting all Binance APIs.

## Architecture

### The "Omni-SDK" Pattern

The new architecture separates **Shared Core** (product-agnostic) from **Product Modules** (Spot, Futures, Options, etc.):

```
Binance::Client (Unified Entry Point)
├── Core (Shared)
│   ├── Transport (HTTP/WebSocket)
│   ├── Authentication (HMAC/RSA)
│   ├── Clock Sync
│   ├── Rate Limiting (Multi-bucket)
│   └── Error Handling
│
├── Spot (/api/v3/*)
├── UMFutures (/fapi/v1/*)
├── CMFutures (/dapi/v1/*)
├── Options (/eapi/v1/*)
├── Margin (/sapi/v1/*)
└── Wallet (/sapi/v1/*)
```

## Installation

```ruby
# Gemfile
gem 'binance', '~> 2.0.0'
```

## Quick Start

### Public Data Only (No Credentials Required)

```ruby
require 'binance'

client = Binance.client

# Get market data without any API key
klines = client.spot.market.klines(symbol: "BTCUSDT", interval: "1h")
ticker = client.spot.market.ticker_24h(symbol: "ETHUSDT")
depth = client.um_futures.market.depth(symbol: "BTCUSDT", limit: 100)
```

### Full Trading Access

```ruby
require 'binance'

client = Binance.client(
  api_key: ENV["BINANCE_API_KEY"],
  secret_key: ENV["BINANCE_SECRET_KEY"],
  testnet: true
)

# Spot Trading
spot_order = client.spot.orders.create(
  symbol: "BTCUSDT",
  side: :buy,
  type: :market,
  quote_order_qty: "1000"
)

# USD-M Futures Trading
futures_order = client.um_futures.place_order(
  symbol: "ETHUSDT",
  side: :buy,
  type: :limit,
  quantity: "1.5",
  price: "2500.50",
  time_in_force: :gtc
)

# Check account balances
balances = client.wallet.coin_info
```

## Generic Products API (Catalog-driven)

Every Binance REST endpoint across all 36 products (888 endpoints) is reachable
through `Binance::Products::API` via the generated endpoint catalog
(`Binance::Core::Catalog`, generated from the official docs by
`script/generate_catalog.rb`).

```ruby
require 'binance'

client = Binance.client

# Any catalog endpoint by action name (method + snake-cased path)
client.spot.request(:get_api_v3_time)                     # => { "serverTime" => ... }
client.spot.request(:get_api_v3_klines, symbol: "BTCUSDT", interval: "1h", limit: 100)
client.wallet.request(:get_sapi_v1_system_status)

# Signed endpoints automatically add timestamp + signature
client.spot.request(:get_api_v3_account)

# Every product key is exposed as an accessor on Binance::Client
client.cm_futures.request(:get_dapi_v1_time)
client.options.request(:get_eapi_v1_time)
client.portfolio_margin.request(:get_papi_v1_ping)
client.simple_earn.request(...)

# Raw paths (for endpoints not in the catalog)
client.product(:spot).get('/api/v3/ping')
client.product(:spot).post('/api/v3/order', symbol: "BTCUSDT", side: "BUY", type: "MARKET", quantity: "0.001")

# Inspect the catalog
Binance::Core::Catalog.for_product(:spot).map { |e| e[:action] }   # all spot actions
Binance::Core::Catalog.find(:spot, :get_api_v3_klines)              # endpoint metadata
```

### Testnet

Products with a public testnet (`spot`, `um_futures`, `cm_futures`, `options`,
`portfolio_margin`, `margin`) automatically route to their testnet host when
`testnet: true`. Products without a sandbox fall back to production with a
one-time warning rather than failing.

```ruby
client = Binance.client(testnet: true)
client.spot.request(:get_api_v3_time)  # => hits https://testnet.binance.vision
```

### Action naming convention

Actions are `#{http_method}_#{snake_cased_path}`:

| Endpoint | Action |
| --- | --- |
| `GET /api/v3/klines` | `:get_api_v3_klines` |
| `POST /api/v3/order` | `:post_api_v3_order` |
| `DELETE /fapi/v1/order` | `:delete_fapi_v1_order` |

Security levels (`NONE`, `MARKET_DATA`, `TRADE`, `USER_DATA`, `USER_STREAM`,
`MARGIN`) are resolved automatically from the catalog; signed requests are
authenticated via the shared `Binance::Core` clock with automatic time sync.

## Security Levels

The SDK supports three security levels automatically:

1. **NONE** - No API key, no signature (public market data)
   ```ruby
   client.spot.market.klines(symbol: "BTCUSDT", interval: "1h")
   ```

2. **API_KEY_ONLY** - API key required, no signature (historical trades)
   ```ruby
   client.spot.market.historical_trades(symbol: "BTCUSDT")
   ```

3. **SIGNED** - API key + signature (orders, account data)
   ```ruby
   client.spot.orders.create(symbol: "BTCUSDT", side: :buy, ...)
   ```

## Product Modules

### Spot API

```ruby
# Market Data
client.spot.market.klines(symbol: "BTCUSDT", interval: "1h", limit: 100)
client.spot.market.depth(symbol: "ETHUSDT", limit: 100)
client.spot.market.trades(symbol: "BTCUSDT", limit: 500)
client.spot.market.ticker_24h(symbol: "BNBUSDT")

# Trading
client.spot.orders.create(
  symbol: "BTCUSDT",
  side: :buy,
  type: :limit,
  quantity: "0.001",
  price: "50000",
  time_in_force: :gtc
)

client.spot.orders.cancel(symbol: "BTCUSDT", order_id: 123456)
client.spot.orders.query(symbol: "BTCUSDT", order_id: 123456)

# Account
account = client.spot.account.info
balances = account[:balances]
```

### USD-M Futures API

```ruby
# Market Data
client.um_futures.market.klines(symbol: "BTCUSDT", interval: "1h")
client.um_futures.market.depth(symbol: "ETHUSDT")
client.um_futures.market.funding_rate(symbol: "BTCUSDT")
client.um_futures.market.open_interest(symbol: "SOLUSDT")

# Trading
client.um_futures.place_order(
  symbol: "ETHUSDT",
  side: :buy,
  type: :limit,
  quantity: "1.0",
  price: "2500",
  position_side: :long,
  time_in_force: :gtc
)

# Batch Orders (NEW!)
client.um_futures.orders.batch_create([
  { symbol: "BTCUSDT", side: :buy, type: :limit, quantity: "0.01", price: "50000" },
  { symbol: "ETHUSDT", side: :sell, type: :limit, quantity: "0.1", price: "3000" }
])

# Order Modification (NEW!)
client.um_futures.orders.modify(
  symbol: "BTCUSDT",
  order_id: 123456,
  price: "51000",
  quantity: "0.02"
)

# Account & Positions
account = client.um_futures.account_info
positions = client.um_futures.positions
balances = client.um_futures.balances

# Position Management (NEW!)
client.um_futures.position.change_mode(dual_side_position: true)  # Hedge Mode
client.um_futures.position.margin_adjust(
  symbol: "BTCUSDT",
  position_side: :long,
  amount: "100",
  type: :add
)

# Income History (NEW!)
income = client.um_futures.income_history(
  income_type: "FUNDING_FEE",
  start_time: Time.now.to_i * 1000 - 86400000,
  end_time: Time.now.to_i * 1000
)
```

### COIN-M Futures API

```ruby
# Similar to UM Futures but with different base URL
client.cm_futures.market.klines(symbol: "BTCUSD_PERP", interval: "1h")
client.cm_futures.place_order(...)
```

### Wallet / SAPI

```ruby
# Coin Information
coins = client.wallet.coin_info

# Deposit Address
address = client.wallet.deposit_address(coin: "USDT", network: "ETH")

# Withdrawal
withdrawal = client.wallet.withdraw(
  coin: "USDT",
  address: "0x...",
  amount: "100",
  network: "ETH"
)

# Transfer between Spot and Futures
client.wallet.universal_transfer(
  type: "MAIN_UMFUTURE",  # Spot -> UM Futures
  asset: "USDT",
  amount: "500"
)
```

## WebSocket Support

### Public Market Streams

```ruby
ws = Binance::WebSocket::Manager.new

# Subscribe to multiple streams
ws.market.subscribe(product: :spot, symbols: ["BTCUSDT", "ETHUSDT"], stream: :trade)
ws.market.subscribe(product: :um_futures, symbols: ["BTCUSDT"], stream: :mark_price)

# Handle events
ws.on(:trade) do |event|
  puts "Trade: #{event[:symbol]} @ #{event[:price]}"
end

ws.connect
```

### Private User Data Stream (NEW!)

```ruby
# Auto-manages ListenKey lifecycle
ws.user_data.listen do |event|
  case event[:type]
  when :order_update
    puts "Order Update: #{event[:order_status]}"
  when :account_update
    puts "Account Balance Changed: #{event[:balances]}"
  end
end
```

## Advanced Features

### BigDecimal Precision

All numeric values use `BigDecimal` to avoid floating-point precision loss:

```ruby
order = client.spot.orders.create(...)
puts order[:price].class  # => BigDecimal
puts order[:quantity].class  # => BigDecimal
```

### Rate Limiting

The SDK automatically tracks rate limits per product:

```ruby
# Check usage
usage = client.um_futures.rate_limit_usage
puts "Request Weight: #{usage[:request_weight][:remaining]} remaining"

# Auto-throttling
client.auto_throttle = true  # Wait before hitting limits
```

### Time Synchronization

```ruby
# Sync time with Binance servers
client.sync_time!

# Get server time offset
offset = client.time_offset  # => Integer (milliseconds)
```

## Endpoint Registry

All endpoints are defined in `Binance::Core::EndpointRegistry`:

```ruby
# Find endpoint metadata
endpoint = Binance::Core::EndpointRegistry.find(:um_futures_trade, :batch_orders)
# => { path: "/fapi/v1/batchOrders", method: :post, security: :trade, weight: 5, ... }

# Check if endpoint exists
Binance::Core::EndpointRegistry.exists?(:spot_market, :klines)  # => true
```

## Migration from binance_usdm

The old API still works for backward compatibility:

```ruby
# Old way (still works)
require 'binance_usdm'
client = Binance::USDM.client(api_key: "...", secret_key: "...")
client.place_order(...)

# New way (recommended)
require 'binance'
client = Binance.client(api_key: "...", secret_key: "...")
client.um_futures.place_order(...)
```

## Missing Features Roadmap

### Phase 1 (Complete) ✓
- [x] Endpoint Registry
- [x] Unified Client structure
- [x] Multi-product constants
- [x] BigDecimal support

### Phase 2 (In Progress)
- [ ] Spot API implementation
- [ ] Wallet/SAPI endpoints
- [ ] User Data Stream (ListenKey management)

### Phase 3 (Planned)
- [ ] COIN-M Futures
- [ ] Options API
- [ ] Margin API
- [ ] WebSocket API (WS-API for trading)

### Phase 4 (Advanced)
- [ ] RSA key support
- [ ] Portfolio Margin (/papi/*)
- [ ] Sub-account routing
- [ ] Combined WebSocket streams

## Testing

```bash
# Run tests
bundle exec rspec

# Test against testnet
export BINANCE_TESTNET=true
bundle exec rspec
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new endpoints
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License

## Resources

- [Binance Spot API Docs](https://binance-docs.github.io/apidocs/spot/en/)
- [Binance Futures API Docs](https://binance-docs.github.io/apidocs/futures/en/)
- [Binance Options API Docs](https://binance-docs.github.io/apidocs/options/en/)
