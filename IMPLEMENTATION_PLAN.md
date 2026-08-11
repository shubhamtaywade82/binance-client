# Binance Ruby SDK - Complete API Support Implementation Plan

## Executive Summary

This document outlines the transformation of the `binance_usdm` gem from a USDⓈ-M Futures-only wrapper into a **complete, unified Binance Ruby SDK** supporting all Binance APIs: Spot, Margin, USDⓈ-M Futures, COIN-M Futures, Options, Wallet, Pay, and more.

---

## Current State Analysis

### What Works Well ✓

1. **Solid Core Architecture**: The existing transport layer, authentication, and rate limiting are well-designed
2. **Time Synchronization**: Clock sync mechanism is properly implemented
3. **Error Handling**: Comprehensive error hierarchy with proper mapping
4. **Rate Limiting**: Multi-bucket rate limit manager exists
5. **WebSocket Base**: Foundation for market data streams exists

### Critical Gaps Identified ✗

Based on the comprehensive audit, here are the missing pieces:

#### 1. User Data Stream (UDS) / Private WebSockets
- **Missing**: ListenKey management (CREATE, KEEP-ALIVE, DELETE)
- **Missing**: Private WebSocket stream for ORDER_TRADE_UPDATE, ACCOUNT_UPDATE
- **Impact**: Paper engines must poll REST APIs, exhausting rate limits

#### 2. Advanced Order Management
- **Missing**: Batch Orders (`/fapi/v1/batchOrders`)
- **Missing**: Order Modification (`PUT /fapi/v1/order`)
- **Missing**: Query Specific Order (`GET /fapi/v1/order`)
- **Missing**: Cancel All Open Orders (`DELETE /fapi/v1/allOpenOrders`)
- **Missing**: Countdown Cancel All (Dead Man's Switch)

#### 3. Position & Risk Management
- **Missing**: Hedge Mode toggle (`/fapi/v1/positionSide/dual`)
- **Missing**: Margin Management (`/fapi/v1/positionMargin`)
- **Missing**: Leverage Brackets (`/fapi/v1/leverageBracket`)
- **Missing**: Income History (`/fapi/v1/income`)

#### 4. Market Data Enhancements
- **Missing**: Mark Price WebSocket streams (properly documented)
- **Missing**: Open Interest history endpoints
- **Missing**: Long/Short Ratio endpoints
- **Missing**: Depth streams for L2 order book construction

#### 5. Infrastructure & Security
- **Partial**: RSA API Key support (currently HMAC only)
- **Partial**: Rate limit header parsing (exists but could be improved)
- **Good**: Timestamp sync exists

#### 6. Multi-Product Support
- **Missing**: Spot API (`/api/v3/*`)
- **Missing**: Margin API (`/sapi/v1/*`)
- **Missing**: COIN-M Futures (`/dapi/v1/*`)
- **Missing**: Options API (`/eapi/v1/*`)
- **Missing**: Wallet/SAPI endpoints

---

## Target Architecture: The "Omni-SDK" Pattern

### Phase 0: Core Extraction (Foundation)

Extract product-agnostic components into `Binance::Core`:

```
lib/binance/
├── core/
│   ├── transport/
│   │   ├── http.rb              # HTTP client (Faraday adapter)
│   │   ├── request.rb           # Request object
│   │   ├── response.rb          # Response object
│   │   └── endpoint_spec.rb     # Endpoint metadata
│   ├── auth/
│   │   ├── hmac_signer.rb       # HMAC SHA256 signing
│   │   ├── rsa_signer.rb        # RSA signing (NEW)
│   │   └── clock.rb             # Time synchronization
│   ├── rate_limit/
│   │   ├── bucket.rb            # Token bucket
│   │   └── multi_manager.rb     # Multi-product rate limits
│   ├── errors/
│   │   └── error_hierarchy.rb   # Unified error classes
│   └── websocket/
│       ├── base_connection.rb   # WS connection management
│       └── stream_router.rb     # Stream normalization
```

### Phase 1: Product Modules

Each Binance product becomes a isolated module:

```
lib/binance/
├── spot/
│   ├── client.rb
│   ├── endpoints/
│   │   ├── market.rb            # GET /api/v3/ticker/*
│   │   ├── trade.rb             # POST /api/v3/order
│   │   └── account.rb           # GET /api/v3/account
│   ├── models/
│   │   ├── order.rb
│   │   ├── trade.rb
│   │   └── ticker.rb
│   └── websocket/
│       └── market_client.rb
│
├── um_futures/                  # Existing USD-M Futures (refactored)
│   ├── client.rb
│   ├── endpoints/
│   │   ├── market.rb
│   │   ├── trade.rb
│   │   ├── account.rb
│   │   └── risk.rb              # NEW: Leverage brackets, income
│   ├── models/
│   │   ├── order.rb
│   │   ├── position.rb
│   │   └── leverage_bracket.rb
│   └── websocket/
│       ├── market_client.rb
│       └── user_data_client.rb  # NEW: Private UDS
│
├── cm_futures/                  # COIN-M Futures
│   └── ... (similar structure)
│
├── options/                     # Options API
│   └── ...
│
├── margin/                      # Cross/Isolated Margin
│   └── ...
│
└── wallet/                      # SAPI endpoints
    ├── deposit.rb
    ├── withdraw.rb
    └── balances.rb
```

### Phase 2: Unified Client

Top-level `Binance::Client` that provides unified access:

```ruby
client = Binance::Client.new(
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

# USD-M Futures
futures_order = client.um_futures.orders.create(
  symbol: "ETHUSDT",
  side: :buy,
  type: :limit,
  quantity: "1.5",
  price: "2500.50"
)

# Wallet Operations
balances = client.wallet.balances
```

---

## Implementation Roadmap

### Week 1-2: Core Refactoring

1. **Rename namespace** from `BinanceUSDM` to `Binance`
2. **Extract core components** into `Binance::Core`
3. **Add RSA signing support** alongside HMAC
4. **Enhance rate limiter** to support multiple buckets per product
5. **Create endpoint registry** with metadata for all ~80 endpoints

### Week 3-4: USD-M Futures Completion

1. **Add missing endpoints**:
   - `/fapi/v1/batchOrders` (POST/DELETE)
   - `/fapi/v1/order` (PUT - modify)
   - `/fapi/v1/order` (GET - query)
   - `/fapi/v1/allOpenOrders` (DELETE)
   - `/fapi/v1/countdownCancelAll` (POST)
   - `/fapi/v1/positionSide/dual` (GET/POST)
   - `/fapi/v1/positionMargin` (POST/HISTORY)
   - `/fapi/v1/leverageBracket` (GET)
   - `/fapi/v1/income` (GET)

2. **Implement User Data Stream**:
   - ListenKey CRUD operations
   - Private WebSocket client
   - Auto keep-alive mechanism

3. **Add depth stream support** for L2 order book

### Week 5-6: Spot API Implementation

1. **Market endpoints**: ticker, depth, trades, klines
2. **Trade endpoints**: place_order, cancel_order, query_order
3. **Account endpoints**: account info, balances
4. **WebSocket streams**: market data (public)

### Week 7-8: Additional Products

1. **COIN-M Futures**: Similar to UM but with different base URLs
2. **Options API**: Contract-specific logic
3. **Margin**: Cross and isolated margin endpoints
4. **Wallet**: Deposit, withdrawal, balance transfers

### Week 9-10: Advanced Features

1. **WebSocket API (WS-API)**: Order placement over WebSocket
2. **Portfolio Margin**: `/papi/*` endpoints
3. **Sub-account routing**: `X-MBX-SUBACCOUNT-ID` header support
4. **Combined WebSocket streams**: Multiplexing support

---

## Endpoint Metadata Matrix (Sample)

Here's the structure for the endpoint registry:

```ruby
ENDPOINT_REGISTRY = {
  # USD-M Futures Market Data
  um_futures: {
    time: {
      path: "/fapi/v1/time",
      method: :get,
      security: :none,
      weight: 1
    },
    exchange_info: {
      path: "/fapi/v1/exchangeInfo",
      method: :get,
      security: :none,
      weight: 10
    },
    depth: {
      path: "/fapi/v1/depth",
      method: :get,
      security: :market,  # API key required but no signature
      weight: 5
    },
    # ... more endpoints
  },
  
  # USD-M Futures Trading
  um_futures_trade: {
    order: {
      path: "/fapi/v1/order",
      method: :post,
      security: :trade,
      weight: 1,
      order_count_10s: 1,
      order_count_1m: 1
    },
    batch_orders: {
      path: "/fapi/v1/batchOrders",
      method: :post,
      security: :trade,
      weight: 5,
      order_count_10s: 5,
      order_count_1m: 5
    },
    # ... more endpoints
  },
  
  # Spot Market Data
  spot_market: {
    ping: {
      path: "/api/v3/ping",
      method: :get,
      security: :none,
      weight: 1
    },
    time: {
      path: "/api/v3/time",
      method: :get,
      security: :none,
      weight: 1
    },
    # ... more endpoints
  }
}.freeze
```

---

## Security Levels Explained

The SDK must support three security levels:

1. **NONE**: No headers, no signature
   - Example: `GET /api/v3/ping`, `GET /api/v3/klines`
   
2. **API_KEY_ONLY**: Inject `X-MBX-APIKEY` header, NO signature
   - Example: `GET /api/v3/historicalTrades`
   - Example: `GET /fapi/v1/depth` (sometimes)
   
3. **SIGNED** (TRADE/USER_DATA): API key + HMAC/RSA signature
   - Example: `POST /api/v3/order`
   - Example: `GET /fapi/v2/positionRisk`

---

## Rate Limit Strategy

Different products have different buckets:

| Product | IP Weight (1min) | UID Orders (10s) | UID Orders (1d) |
|---------|------------------|------------------|-----------------|
| Spot | 6000 | 10 | 200,000 |
| UM Futures | 2400 | 300 | N/A |
| CM Futures | 2400 | 2400 | N/A |
| Options | 400 (5s) | 100 | N/A |

The `MultiManager` will maintain separate buckets:
- `spot_ip_bucket`
- `spot_uid_bucket`
- `um_futures_ip_bucket`
- `um_futures_uid_bucket`
- etc.

---

## WebSocket Architecture

### Public Market Streams

```ruby
# Unified interface
client.ws.market.subscribe(
  product: :spot,
  symbol: "BTCUSDT",
  stream: :trade
)

client.ws.market.subscribe(
  product: :um_futures,
  symbol: "ETHUSDT",
  stream: :mark_price
)
```

### Private User Data Stream

```ruby
# Auto-manages ListenKey lifecycle
client.ws.user_data.listen do |event|
  case event[:type]
  when :order_update
    # Handle ORDER_TRADE_UPDATE
  when :account_update
    # Handle ACCOUNT_UPDATE
  end
end
```

---

## BigDecimal vs Float

**Critical**: All numeric values must use `BigDecimal` to avoid precision loss:

```ruby
# WRONG - Float precision loss
price = 0.1 + 0.2  # => 0.30000000000000004

# CORRECT - BigDecimal precision
require 'bigdecimal'
price = BigDecimal('0.1') + BigDecimal('0.2')  # => 0.3
```

Models will automatically convert numeric strings to BigDecimal:

```ruby
class Order < BaseModel
  attribute :price, BigDecimal
  attribute :quantity, BigDecimal
  attribute :cumulative_quote_qty, BigDecimal
end
```

---

## Testing Strategy

1. **Unit Tests**: Each resource, model, helper
2. **Integration Tests**: Against Binance Testnet
3. **VCR Cassettes**: Record/replay API responses for CI
4. **Rate Limit Tests**: Ensure throttling works correctly
5. **WebSocket Tests**: Mock WS connections

---

## Migration Path for Existing Users

Maintain backward compatibility during transition:

```ruby
# Old usage (still works)
client = BinanceUSDM.client(api_key: "...", secret_key: "...")

# New usage (recommended)
client = Binance::Client.new(api_key: "...", secret_key: "...")
client.um_futures.orders.create(...)  # Same functionality
```

---

## Next Immediate Steps

1. **Create the EndpointSpec matrix** for all ~80 USD-M Futures endpoints
2. **Refactor constants** to support multiple products
3. **Add batch order endpoints** to UM Futures
4. **Implement ListenKey management** for User Data Stream
5. **Add order modification endpoint** (PUT /fapi/v1/order)

This roadmap transforms the gem from a "thin REST wrapper" into an "institutional-grade trading SDK" capable of powering professional algorithmic trading systems in Ruby.
