# frozen_string_literal: true

module Binance
  module Constants
    # Base URLs for all Binance products
    module Urls
      # Spot
      SPOT_REST_API_BASE = "https://api.binance.com"
      SPOT_TESTNET_REST_API_BASE = "https://testnet.binance.vision"
      SPOT_WEBSOCKET_BASE = "wss://stream.binance.com:9443"
      SPOT_TESTNET_WEBSOCKET_BASE = "wss://testnet.binance.vision/ws"
      
      # USD-M Futures
      UM_FUTURES_REST_API_BASE = "https://fapi.binance.com"
      UM_FUTURES_TESTNET_REST_API_BASE = "https://testnet.binancefuture.com"
      UM_FUTURES_WEBSOCKET_BASE = "wss://fstream.binance.com"
      UM_FUTURES_TESTNET_WEBSOCKET_BASE = "wss://fstream.binancefuture.com"
      
      # COIN-M Futures
      CM_FUTURES_REST_API_BASE = "https://dapi.binance.com"
      CM_FUTURES_TESTNET_REST_API_BASE = "https://testnet.binancefuture.com"
      CM_FUTURES_WEBSOCKET_BASE = "wss://dstream.binance.com"
      CM_FUTURES_TESTNET_WEBSOCKET_BASE = "wss://dstream.binancefuture.com"
      
      # Options
      OPTIONS_REST_API_BASE = "https://eapi.binance.com"
      OPTIONS_TESTNET_REST_API_BASE = "https://testnet.binanceoptions.com"
      OPTIONS_WEBSOCKET_BASE = "wss://nbstream.binance.com"
      OPTIONS_TESTNET_WEBSOCKET_BASE = "wss://nbstream.binancefuture.com"
      
      # Margin / SAPI
      MARGIN_REST_API_BASE = "https://api.binance.com"
      MARGIN_TESTNET_REST_API_BASE = "https://testnet.binance.vision"
      
      # Portfolio Margin (PAPI)
      PORTFOLIO_MARGIN_REST_API_BASE = "https://papi.binance.com"
      PORTFOLIO_MARGIN_TESTNET_REST_API_BASE = "https://testnet.binancefuture.com"
    end
    
    # HTTP methods
    HTTP_METHODS = {
      GET: "GET",
      POST: "POST",
      PUT: "PUT",
      DELETE: "DELETE"
    }.freeze
    
    # Security types
    SECURITY_TYPES = {
      NONE: :none,              # No API key, no signature
      MARKET: :market,          # API key only, no signature
      TRADE: :trade,            # API key + signature
      USER_DATA: :user_data,    # API key + signature
      SIGNED: :signed           # Alias for :trade
    }.freeze
    
    # Encoding types
    ENCODING_TYPES = {
      QUERY: :query,            # Query string parameters
      FORM: :form,              # URL-encoded form data
      JSON: :json               # JSON body
    }.freeze
    
    # Product types
    PRODUCTS = {
      SPOT: :spot,
      UM_FUTURES: :um_futures,
      CM_FUTURES: :cm_futures,
      OPTIONS: :options,
      MARGIN: :margin,
      WALLET: :wallet
    }.freeze
  end
end
