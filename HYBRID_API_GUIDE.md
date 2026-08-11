# BinanceUSDM SDK - Hybrid API Style Guide

The BinanceUSDM SDK now supports **both** explicit client usage AND class-method/ActiveRecord-style usage. This gives you the best of both worlds: developer convenience and production flexibility.

## Quick Start

### Option 1: Class-Method Style (Recommended for simple apps)

```ruby
require 'binance_usdm'

# Configure once at application startup
BinanceUSDM.configure do |config|
  config.api_key = ENV["BINANCE_API_KEY"]
  config.secret_key = ENV["BINANCE_SECRET_KEY"]
  config.testnet = false
end

# Use class methods directly - no need to pass client around!
order = BinanceUSDM::Resources::Order.create(
  symbol: "ETHUSDT",
  side: :buy,
  type: :market,
  quantity: "0.1"
)

position = BinanceUSDM::Resources::Account.positions(symbol: "ETHUSDT").first

price = BinanceUSDM::Resources::Market.price("BTCUSDT")

klines = BinanceUSDM::Resources::Market.klines(
  symbol: "ETHUSDT",
  interval: "1m",
  limit: 100
)
```

### Option 2: Explicit Client Style (Recommended for multi-account apps)

```ruby
require 'binance_usdm'

# Create client explicitly
client = BinanceUSDM.client(
  api_key: ENV["BINANCE_API_KEY"],
  secret_key: ENV["BINANCE_SECRET_KEY"],
  testnet: false
)

# Use client object
order = client.order.place(
  symbol: "ETHUSDT",
  side: :buy,
  type: :market,
  quantity: "0.1"
)

position = client.account.positions(symbol: "ETHUSDT").first

price = client.market.prices(symbol: "BTCUSDT")
```

### Option 3: Multi-Account Support with Scoped Clients

```ruby
require 'binance_usdm'

# Create multiple clients for different accounts
account_a = BinanceUSDM.client(
  api_key: ENV["ACCOUNT_A_API_KEY"],
  secret_key: ENV["ACCOUNT_A_SECRET_KEY"]
)

account_b = BinanceUSDM.client(
  api_key: ENV["ACCOUNT_B_API_KEY"],
  secret_key: ENV["ACCOUNT_B_SECRET_KEY"]
)

# Use .using() for thread-safe scoped operations
BinanceUSDM::Resources::Order.using(account_a) do
  BinanceUSDM::Resources::Order.create(
    symbol: "ETHUSDT",
    side: :buy,
    type: :market,
    quantity: "0.1"
  )
end

BinanceUSDM::Resources::Order.using(account_b) do
  BinanceUSDM::Resources::Order.create(
    symbol: "ETHUSDT",
    side: :sell,
    type: :market,
    quantity: "0.1"
  )
end

# Or use block-style at module level
BinanceUSDM.using(account_a) do
  BinanceUSDM::Resources::Account.info
  BinanceUSDM::Resources::Position.all
end
```

## Available Class Methods

### Orders (`BinanceUSDM::Resources::Order`)

```ruby
# Create order
BinanceUSDM::Resources::Order.create(
  symbol: "ETHUSDT",
  side: :buy,
  type: :limit,
  quantity: "0.1",
  price: "2500",
  time_in_force: :gtc
)

# Find order
BinanceUSDM::Resources::Order.find(symbol: "ETHUSDT", order_id: 123456)

# Get open orders
BinanceUSDM::Resources::Order.open(symbol: "ETHUSDT")  # For specific symbol
BinanceUSDM::Resources::Order.open  # All symbols

# Cancel order
BinanceUSDM::Resources::Order.cancel(symbol: "ETHUSDT", order_id: 123456)

# Cancel all orders for a symbol
BinanceUSDM::Resources::Order.cancel_all(symbol: "ETHUSDT")

# Batch cancel
BinanceUSDM::Resources::Order.batch_cancel(
  symbol: "ETHUSDT",
  order_ids: [123, 456, 789]
)
```

### Account (`BinanceUSDM::Resources::Account`)

```ruby
# Get account info
account = BinanceUSDM::Resources::Account.info

# Get balances
balances = BinanceUSDM::Resources::Account.balance

# Get positions
positions = BinanceUSDM::Resources::Account.positions
eth_position = BinanceUSDM::Resources::Account.positions(symbol: "ETHUSDT").first

# Change leverage
BinanceUSDM::Resources::Account.change_leverage(
  symbol: "ETHUSDT",
  leverage: 10
)

# Change margin mode
BinanceUSDM::Resources::Account.change_margin_mode(
  symbol: "ETHUSDT",
  margin_mode: "ISOLATED"
)

# Get income history
income = BinanceUSDM::Resources::Account.income_history(
  symbol: "ETHUSDT",
  income_type: "COMMISSION",
  limit: 100
)
```

### Market Data (`BinanceUSDM::Resources::Market`)

```ruby
# Get latest price
price = BinanceUSDM::Resources::Market.price("BTCUSDT")

# Get all prices
prices = BinanceUSDM::Resources::Market.price

# Get 24hr ticker
ticker = BinanceUSDM::Resources::Market.ticker_24h(symbol: "ETHUSDT")

# Get klines/candlesticks
klines = BinanceUSDM::Resources::Market.klines(
  symbol: "ETHUSDT",
  interval: "1m",
  limit: 100
)

# Get order book depth
depth = BinanceUSDM::Resources::Market.depth(symbol: "ETHUSDT", limit: 20)

# Get funding rate history
funding = BinanceUSDM::Resources::Market.funding_rate_history(
  symbol: "ETHUSDT",
  limit: 100
)

# Get open interest
oi = BinanceUSDM::Resources::Market.open_interest(symbol: "ETHUSDT")

# Get exchange info / symbols
symbols = BinanceUSDM::Resources::Market.instruments
ethusdt_info = BinanceUSDM::Resources::Market.find_symbol("ETHUSDT")
```

## Architecture

The hybrid design works as follows:

1. **Class methods delegate to a client**: When you call `BinanceUSDM::Resources::Order.create(...)`, it internally calls `client.order.place(...)` where `client` is either:
   - The thread-local client (if using `.using()`)
   - The default client (`BinanceUSDM.default_client`)

2. **Default client is lazy-loaded**: The first time you use a class method, it creates a client from your configuration or environment variables.

3. **Thread-safe**: The `.using()` method stores the client in `Thread.current[]`, so it's safe to use in multi-threaded applications.

## Best Practices

### ✅ DO use class methods when:
- Building a simple single-account bot
- Writing quick scripts or prototypes
- You want Rails-like ergonomics
- Your app has one Binance account

### ✅ DO use explicit clients when:
- Supporting multiple Binance accounts
- Building a multi-tenant application
- You need fine-grained control over credentials
- Writing tests with mock clients

### ⚠️ AVOID:
- Mixing both styles in the same codebase without clear boundaries
- Using class methods without configuring credentials first
- Assuming class methods work without calling `configure` or setting env vars

## Error Handling

```ruby
begin
  order = BinanceUSDM::Resources::Order.create(
    symbol: "ETHUSDT",
    side: :buy,
    type: :market,
    quantity: "0.1"
  )
rescue BinanceUSDM::ConfigurationError => e
  # Raised when no credentials are configured
  puts "Configure credentials first: #{e.message}"
  
rescue BinanceUSDM::ApiError => e
  # General API error
  puts "API error: #{e.message}"
  
rescue BinanceUSDM::OrderError => e
  # Order-specific error
  puts "Order error: #{e.message}"
end
```

## Testing

```ruby
# Test with explicit client (recommended)
RSpec.describe "Order creation" do
  let(:client) do
    BinanceUSDM.client(
      api_key: "test_key",
      secret_key: "test_secret",
      testnet: true
    )
  end
  
  it "creates an order" do
    order = client.order.place(
      symbol: "ETHUSDT",
      side: :buy,
      type: :market,
      quantity: "0.1"
    )
    expect(order.symbol).to eq("ETHUSDT")
  end
end

# Test with class methods and scoped client
RSpec.describe "Order creation with class methods" do
  let(:client) { BinanceUSDM.client(api_key: "...", secret_key: "...", testnet: true) }
  
  it "creates an order" do
    BinanceUSDM::Resources::Order.using(client) do
      order = BinanceUSDM::Resources::Order.create(
        symbol: "ETHUSDT",
        side: :buy,
        type: :market,
        quantity: "0.1"
      )
      expect(order.symbol).to eq("ETHUSDT")
    end
  end
end
```

## Migration Guide

### From explicit client to class methods:

**Before:**
```ruby
client = BinanceUSDM.client(api_key: "...", secret_key: "...")
order = client.order.place(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
```

**After:**
```ruby
BinanceUSDM.configure do |config|
  config.api_key = "..."
  config.secret_key = "..."
end
order = BinanceUSDM::Resources::Order.create(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
```

### From class methods to explicit client:

**Before:**
```ruby
BinanceUSDM.configure do |config|
  config.api_key = "..."
  config.secret_key = "..."
end
order = BinanceUSDM::Resources::Order.create(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
```

**After:**
```ruby
client = BinanceUSDM.client(api_key: "...", secret_key: "...")
order = client.order.place(symbol: "ETHUSDT", side: :buy, type: :market, quantity: "0.1")
```

Both styles work seamlessly together!
