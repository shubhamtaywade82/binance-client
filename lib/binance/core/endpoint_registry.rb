# frozen_string_literal: true

module Binance
  module Core
    # Endpoint Registry - Complete metadata for all Binance API endpoints
    # This is the source of truth for endpoint specifications
    # Based on: https://binance-docs.github.io/apidocs/futures/en/
    module EndpointRegistry
      # Security Types:
      #   :none - No API key, no signature (public market data)
      #   :market - API key required, no signature (some market data)
      #   :trade - API key + signature required (order placement/modification)
      #   :user_data - API key + signature required (account/position data)
      #   :signed - Alias for :trade
      
      # Encoding Types:
      #   :query - Parameters in query string (GET, DELETE)
      #   :form - URL-encoded form data (POST, PUT)
      #   :json - JSON body (some batch operations)

      ENDPOINTS = {
        # =============================================================================
        # USDⓈ-M FUTURES - MARKET DATA ENDPOINTS
        # =============================================================================
        um_futures_market: {
          # Basic Market Data
          time: {
            path: "/fapi/v1/time",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 1,
            description: "Test connectivity to the Rest API and get server time"
          },
          
          exchange_info: {
            path: "/fapi/v1/exchangeInfo",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 10,
            description: "Current exchange trading rules and symbol information"
          },
          
          depth: {
            path: "/fapi/v1/depth",
            method: :get,
            security: :market,
            encoding: :query,
            weight: [5, 10, 20, 50, 100, 500, 1000, 5000], # Varies by limit
            description: "Order Book Depth",
            params: {
              symbol: { required: true, type: String },
              limit: { required: false, default: 100, values: [5, 10, 20, 50, 100, 500, 1000, 5000] }
            }
          },
          
          trades: {
            path: "/fapi/v1/trades",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 50,
            description: "Recent Trades List"
          },
          
          historical_trades: {
            path: "/fapi/v1/historicalTrades",
            method: :get,
            security: :market,
            encoding: :query,
            weight: 50,
            description: "Old Trades Lookup (requires API key)"
          },
          
          agg_trades: {
            path: "/fapi/v1/aggTrades",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Compressed/Aggregate Trade Streams"
          },
          
          klines: {
            path: "/fapi/v1/klines",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2, 5, 10, 15, 30, 60, 120, 240, 360, 720, 1440, 10080, 43200],
            description: "Kline/Candlestick Data"
          },
          
          continuous_klines: {
            path: "/fapi/v1/continuousKlines",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Continuous Contract Kline/Candlestick Data"
          },
          
          index_price_klines: {
            path: "/fapi/v1/indexPriceKlines",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Index Price Kline/Candlestick Data"
          },
          
          mark_price_klines: {
            path: "/fapi/v1/markPriceKlines",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Mark Price Kline/Candlestick Data"
          },
          
          premium_index: {
            path: "/fapi/v1/premiumIndex",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Get Premium Index"
          },
          
          funding_rate: {
            path: "/fapi/v1/fundingRate",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Get Funding Rate History"
          },
          
          ticker_24h: {
            path: "/fapi/v1/ticker/24hr",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 40], # 1 for single symbol, 40 for all symbols
            description: "24hr Ticker Price Change Statistics"
          },
          
          ticker_price: {
            path: "/fapi/v1/ticker/price",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2], # 1 for single symbol, 2 for all symbols
            description: "Symbol Price Ticker"
          },
          
          book_ticker: {
            path: "/fapi/v1/ticker/bookTicker",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2], # 1 for single symbol, 2 for all symbols
            description: "Symbol Order Book Ticker"
          },
          
          open_interest: {
            path: "/fapi/v1/openInterest",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Get Present Open Interest"
          },
          
          open_interest_hist: {
            path: "/futures/data/openInterestHist",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Open Interest Statistics (SAPI)"
          },
          
          top_long_short_ratio: {
            path: "/futures/data/topLongShortAccountRatio",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Top Trader Long/Short Ratio (Accounts)"
          },
          
          long_short_ratio: {
            path: "/futures/data/topLongShortPositionRatio",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Top Trader Long/Short Ratio (Positions)"
          },
          
          global_long_short_ratio: {
            path: "/futures/data/globalLongShortAccountRatio",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Global Long/Short Ratio"
          },
          
          taker_volume: {
            path: "/futures/data/takerlongshortRatio",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Taker Buy/Sell Volume"
          },
          
          basis: {
            path: "/futures/data/basis",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Basis Data"
          }
        },
        
        # =============================================================================
        # USDⓈ-M FUTURES - TRADING ENDPOINTS
        # =============================================================================
        um_futures_trade: {
          order: {
            path: "/fapi/v1/order",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_10s: 1,
            order_count_1m: 1,
            description: "Place a new order (LIMIT/MARKET/STOP/etc.)"
          },
          
          order_query: {
            path: "/fapi/v1/order",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: 1,
            description: "Query an existing order status"
          },
          
          order_modify: {
            path: "/fapi/v1/order",
            method: :put,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_10s: 1,
            order_count_1m: 1,
            description: "Modify an existing order (price/quantity)"
          },
          
          order_cancel: {
            path: "/fapi/v1/order",
            method: :delete,
            security: :trade,
            encoding: :query,
            weight: 1,
            order_count_10s: 1,
            order_count_1m: 1,
            description: "Cancel an active order"
          },
          
          order_cancel_replace: {
            path: "/fapi/v1/order/cancelReplace",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_10s: 2,
            order_count_1m: 2,
            description: "Cancel and replace order in one request"
          },
          
          batch_orders: {
            path: "/fapi/v1/batchOrders",
            method: :post,
            security: :trade,
            encoding: :json,
            weight: 5,
            order_count_10s: 5,
            order_count_1m: 5,
            description: "Place multiple orders in one request (max 5)"
          },
          
          batch_orders_cancel: {
            path: "/fapi/v1/batchOrders",
            method: :delete,
            security: :trade,
            encoding: :json,
            weight: 5,
            order_count_10s: 5,
            order_count_1m: 5,
            description: "Cancel multiple orders in one request (max 5)"
          },
          
          all_open_orders_cancel: {
            path: "/fapi/v1/allOpenOrders",
            method: :delete,
            security: :trade,
            encoding: :query,
            weight: 1,
            description: "Cancel all open orders for a symbol"
          },
          
          countdown_cancel_all: {
            path: "/fapi/v1/countdownCancelAll",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_10s: 1,
            order_count_1m: 1,
            description: "Dead Man's Switch - Auto-cancel if connection lost"
          },
          
          open_orders: {
            path: "/fapi/v1/openOrders",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: [1, 40], # 1 for single symbol, 40 for all
            description: "Get all open orders"
          },
          
          all_orders: {
            path: "/fapi/v1/allOrders",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: 5,
            description: "Get all orders (active, filled, cancelled)"
          },
          
          user_trades: {
            path: "/fapi/v1/userTrades",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: 5,
            description: "Get account trade history"
          }
        },
        
        # =============================================================================
        # USDⓈ-M FUTURES - ACCOUNT & POSITION ENDPOINTS
        # =============================================================================
        um_futures_account: {
          position_side_dual: {
            path: "/fapi/v1/positionSide/dual",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get current position mode (Hedge/One-Way)"
          },
          
          position_side_dual_change: {
            path: "/fapi/v1/positionSide/dual",
            method: :post,
            security: :user_data,
            encoding: :form,
            weight: 5,
            description: "Change position mode (Hedge/One-Way)"
          },
          
          account_info: {
            path: "/fapi/v2/account",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Futures Account Balance & Position Info"
          },
          
          position_risk: {
            path: "/fapi/v2/positionRisk",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get Positions Risk (Unrealized PnL, Entry Price)"
          },
          
          balance: {
            path: "/fapi/v3/balance",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get Account Balance (USDT only)"
          },
          
          leverage: {
            path: "/fapi/v1/leverage",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Change Initial Leverage"
          },
          
          margin_type: {
            path: "/fapi/v1/marginType",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Change Margin Mode (ISOLATED/CROSSED)"
          },
          
          position_margin: {
            path: "/fapi/v1/positionMargin",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Modify Isolated Position Margin"
          },
          
          position_margin_history: {
            path: "/fapi/v1/positionMargin/history",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get Position Margin Change History"
          },
          
          income: {
            path: "/fapi/v1/income",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get Income History (Funding Fees, Realized PnL)"
          },
          
          leverage_bracket: {
            path: "/fapi/v1/leverageBracket",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Get Notional and Leverage Brackets"
          },
          
          adl_quantile: {
            path: "/fapi/v1/adlQuantile",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Get ADL Quantile Estimation"
          },
          
          commission_rate: {
            path: "/fapi/v1/commissionRate",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Get User Commission Rates"
          }
        },
        
        # =============================================================================
        # USDⓈ-M FUTURES - LISTEN KEY (USER DATA STREAM)
        # =============================================================================
        um_futures_listen_key: {
          listen_key_create: {
            path: "/fapi/v1/listenKey",
            method: :post,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Create ListenKey for User Data Stream"
          },
          
          listen_key_keepalive: {
            path: "/fapi/v1/listenKey",
            method: :put,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Keep-alive ListenKey (extend validity)"
          },
          
          listen_key_delete: {
            path: "/fapi/v1/listenKey",
            method: :delete,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Close ListenKey (close WebSocket stream)"
          }
        },
        
        # =============================================================================
        # USDⓈ-M FUTURES - ALGO ORDERS
        # =============================================================================
        um_futures_algo: {
          algo_order_create: {
            path: "/fapi/v1/algo/order",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_10s: 1,
            order_count_1m: 1,
            description: "Create Algo Order (TWAP/VP)"
          },
          
          algo_order_cancel: {
            path: "/fapi/v1/algo/order",
            method: :delete,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Cancel Algo Order"
          },
          
          algo_order_open: {
            path: "/fapi/v1/algo/openOrders",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Get Open Algo Orders"
          },
          
          algo_order_history: {
            path: "/fapi/v1/algo/subOrders",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Get Algo Order Sub-orders History"
          }
        },
        
        # =============================================================================
        # SPOT - MARKET DATA ENDPOINTS
        # =============================================================================
        spot_market: {
          ping: {
            path: "/api/v3/ping",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 1,
            description: "Test connectivity"
          },
          
          time: {
            path: "/api/v3/time",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 1,
            description: "Get server time"
          },
          
          exchange_info: {
            path: "/api/v3/exchangeInfo",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 10,
            description: "Exchange info and trading rules"
          },
          
          depth: {
            path: "/api/v3/depth",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [5, 10, 20, 50, 100, 500, 1000, 5000],
            description: "Order Book Depth"
          },
          
          trades: {
            path: "/api/v3/trades",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 50,
            description: "Recent Trades"
          },
          
          historical_trades: {
            path: "/api/v3/historicalTrades",
            method: :get,
            security: :market,
            encoding: :query,
            weight: 50,
            description: "Historical Trades (requires API key)"
          },
          
          agg_trades: {
            path: "/api/v3/aggTrades",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 5,
            description: "Aggregate Trades"
          },
          
          klines: {
            path: "/api/v3/klines",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2, 5, 10, 15, 30, 60, 120, 240, 360, 720, 1440, 10080, 43200],
            description: "Kline/Candlestick Data"
          },
          
          avg_price: {
            path: "/api/v3/avgPrice",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 1,
            description: "Current Average Price"
          },
          
          ticker_24h: {
            path: "/api/v3/ticker/24hr",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 40],
            description: "24hr Ticker"
          },
          
          ticker_price: {
            path: "/api/v3/ticker/price",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2],
            description: "Symbol Price"
          },
          
          book_ticker: {
            path: "/api/v3/ticker/bookTicker",
            method: :get,
            security: :none,
            encoding: :query,
            weight: [1, 2],
            description: "Best Bid/Ask"
          }
        },
        
        # =============================================================================
        # SPOT - TRADING ENDPOINTS
        # =============================================================================
        spot_trade: {
          order_test: {
            path: "/api/v3/order/test",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Test order creation (no actual order)"
          },
          
          order: {
            path: "/api/v3/order",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_1s: 1,
            description: "Place new order"
          },
          
          order_query: {
            path: "/api/v3/order",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: 1,
            description: "Query order status"
          },
          
          order_cancel: {
            path: "/api/v3/order",
            method: :delete,
            security: :trade,
            encoding: :query,
            weight: 1,
            description: "Cancel order"
          },
          
          order_cancel_replace: {
            path: "/api/v3/order/cancelAndReplace",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            order_count_1s: 2,
            description: "Cancel and replace order"
          },
          
          open_orders: {
            path: "/api/v3/openOrders",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: [1, 40],
            description: "Current open orders"
          },
          
          all_orders: {
            path: "/api/v3/allOrders",
            method: :get,
            security: :trade,
            encoding: :query,
            weight: 5,
            description: "All orders history"
          },
          
          my_trades: {
            path: "/api/v3/myTrades",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Trade history"
          }
        },
        
        # =============================================================================
        # SPOT - ACCOUNT ENDPOINTS
        # =============================================================================
        spot_account: {
          account: {
            path: "/api/v3/account",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Account balances and permissions"
          },
          
          my_allocations: {
            path: "/api/v3/myAllocations",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: " allocations"
          }
        },
        
        # =============================================================================
        # WALLET / SAPI ENDPOINTS
        # =============================================================================
        wallet_sapi: {
          system_status: {
            path: "/sapi/v1/system/status",
            method: :get,
            security: :none,
            encoding: :query,
            weight: 1,
            description: "System Status"
          },
          
          coin_info: {
            path: "/sapi/v1/capital/config/getall",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "All Coins' Information"
          },
          
          account_snapshot: {
            path: "/sapi/v1/accountSnapshot",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 5,
            description: "Daily Account Snapshot"
          },
          
          disable_fast_withdraw: {
            path: "/sapi/v1/account/disableFastWithdrawSwitch",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Disable Fast Withdraw"
          },
          
          enable_fast_withdraw: {
            path: "/sapi/v1/account/enableFastWithdrawSwitch",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Enable Fast Withdraw"
          },
          
          withdraw: {
            path: "/sapi/v1/capital/withdraw/apply",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Apply Withdraw"
          },
          
          deposit_address: {
            path: "/sapi/v1/capital/deposit/address",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Fetch Deposit Address"
          },
          
          deposit_history: {
            path: "/sapi/v1/capital/deposit/hisrec",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Fetch Deposit History"
          },
          
          withdraw_history: {
            path: "/sapi/v1/capital/withdraw/history",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Fetch Withdraw History"
          },
          
          api_key_permissions: {
            path: "/sapi/v1/account/apiRestrictions",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Fetch API Key Permissions"
          },
          
          universal_transfer: {
            path: "/sapi/v1/transfer/universal",
            method: :post,
            security: :trade,
            encoding: :form,
            weight: 1,
            description: "Universal Transfer (Spot <-> Futures)"
          },
          
          transfer_history: {
            path: "/sapi/v1/transfer/queryUserUniversalTransferHistory",
            method: :get,
            security: :user_data,
            encoding: :query,
            weight: 1,
            description: "Query Universal Transfer History"
          }
        }
      }.freeze
      
      # Helper method to find endpoint by product and name
      def self.find(product, name)
        ENDPOINTS.dig(product, name)
      end
      
      # Helper method to check if endpoint exists
      def self.exists?(product, name)
        ENDPOINTS.key?(product) && ENDPOINTS[product].key?(name)
      end
      
      # Get all endpoints for a product
      def self.for_product(product)
        ENDPOINTS[product] || {}
      end
      
      # Get endpoint path helper
      def self.path_for(product, name)
        endpoint = find(product, name)
        endpoint ? endpoint[:path] : nil
      end
      
      # Get endpoint method helper
      def self.method_for(product, name)
        endpoint = find(product, name)
        endpoint ? endpoint[:method] : nil
      end
      
      # Get security type helper
      def self.security_for(product, name)
        endpoint = find(product, name)
        endpoint ? endpoint[:security] : nil
      end
    end
  end
end
