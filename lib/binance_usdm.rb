# frozen_string_literal: true

require "json"
require "logger"
require "zeitwerk"
require "faraday"

# Core files
require_relative "BinanceUSDM/version"
require_relative "BinanceUSDM/errors"
require_relative "BinanceUSDM/constants"

# Enums
require_relative "BinanceUSDM/enums/order_type"

# Helpers
require_relative "BinanceUSDM/helpers/signature_helper"

# Transport layer
require_relative "BinanceUSDM/transport/request"
require_relative "BinanceUSDM/transport/response"
require_relative "BinanceUSDM/transport/endpoint"
require_relative "BinanceUSDM/transport/http"

# Authentication
require_relative "BinanceUSDM/authentication/clock"

# Rate limiting
require_relative "BinanceUSDM/rate_limit/bucket"
require_relative "BinanceUSDM/rate_limit/manager"

# Core classes
require_relative "BinanceUSDM/core/base_api"
require_relative "BinanceUSDM/core/base_model"

# Client
require_relative "BinanceUSDM/client"

# Models
require_relative "BinanceUSDM/models"

# Resources
require_relative "BinanceUSDM/resources/order"
require_relative "BinanceUSDM/resources/account"
require_relative "BinanceUSDM/resources/market"
require_relative "BinanceUSDM/resources/algo_order"

# WebSocket
require_relative "BinanceUSDM/websocket/base_client"
require_relative "BinanceUSDM/websocket/market_client"

module BinanceUSDM
  class Error < StandardError; end
  
  # Configure the BinanceUSDM client
  # @yieldparam config [Configuration] Configuration instance
  # @return [Configuration]
  def self.configure
    @configuration ||= Configuration.new
    yield @configuration if block_given?
    @configuration
  end
  
  # Get current configuration
  # @return [Configuration, nil]
  def self.configuration
    @configuration
  end
  
  # Configuration class for BinanceUSDM client
  class Configuration
    attr_accessor :api_key, :secret_key, :testnet, :logger, :recv_window
    
    def initialize
      @testnet = false
      @logger = nil
      @recv_window = 5000
    end
  end
  
  # Get or create the default client used by class methods
  # @return [API] Default API client
  def self.default_client
    @default_client ||= begin
      api_key = configuration&.api_key || ENV["BINANCE_API_KEY"]
      secret_key = configuration&.secret_key || ENV["BINANCE_SECRET_KEY"]
      testnet = configuration&.testnet || false
      
      raise ConfigurationError, "No API credentials configured. Call BinanceUSDM.configure or pass api_key/secret_key to client" unless api_key && secret_key
      
      API.new(api_key: api_key, secret_key: secret_key, testnet: testnet)
    end
  end
  
  # Set the default client
  # @param client [API] Client to use as default
  # @return [API]
  def self.default_client=(client)
    @default_client = client
  end
  
  # Create a new API client instance
  # @param api_key [String] Binance API key
  # @param secret_key [String] Binance API secret
  # @param testnet [Boolean] Use testnet (default: false)
  # @return [API] API client
  def self.client(api_key: nil, secret_key: nil, testnet: nil)
    api_key ||= configuration&.api_key || ENV["BINANCE_API_KEY"]
    secret_key ||= configuration&.secret_key || ENV["BINANCE_SECRET_KEY"]
    testnet = testnet.nil? ? (configuration&.testnet || false) : testnet
    
    API.new(api_key: api_key, secret_key: secret_key, testnet: testnet)
  end
  
  # Execute block with a specific client for thread-safe multi-account support
  # @param client [API] Client to use within the block
  # @yield Block to execute with the specified client
  # @return Result of the block
  def self.using(client)
    previous_client = Thread.current[:binance_usdm_client]
    Thread.current[:binance_usdm_client] = client
    yield
  ensure
    Thread.current[:binance_usdm_client] = previous_client
  end
  
  # Custom error for missing configuration
  class ConfigurationError < Error; end
  
  # Main API class providing access to all resources
  class API
    attr_reader :client, :order, :account, :market, :algo_orders, :ws
    
    # Initialize the API client
    # @param api_key [String] Binance API key
    # @param secret_key [String] Binance API secret
    # @param testnet [Boolean] Use testnet (default: false)
    # @param logger [Logger] Custom logger (optional)
    def initialize(api_key:, secret_key:, testnet: false, logger: nil)
      @client = Client.new(
        api_key: api_key,
        secret_key: secret_key,
        testnet: testnet,
        logger: logger
      )
      
      @order = Resources::Order.new(@client)
      @account = Resources::Account.new(@client)
      @market = Resources::Market.new(@client)
      @algo_orders = Resources::AlgoOrder.new(@client)
      @ws = WebSocket::MarketClient.new(testnet: testnet, logger: logger)
    end
    
    # Synchronize time with Binance server
    # @return [Integer] Server time in milliseconds
    def sync_time!
      client.sync_time!
    end
    
    # Get time offset
    # @return [Integer] Time offset in milliseconds
    def time_offset
      client.time_offset
    end
    
    # Get rate limiter usage stats
    # @return [Hash] Usage statistics
    def rate_limit_usage
      client.rate_limiter.usage
    end
    
    # Convenience methods delegating to resources
    
    # Place a new order
    # @see Resources::Order#place
    def place_order(**kwargs)
      @order.place(**kwargs)
    end
    
    # Test order creation
    # @see Resources::Order#test
    def test_order(**kwargs)
      @order.test(**kwargs)
    end
    
    # Cancel an order
    # @see Resources::Order#cancel
    def cancel_order(**kwargs)
      @order.cancel(**kwargs)
    end
    
    # Get open orders
    # @see Resources::Order#open_orders
    def open_orders(symbol: nil)
      @order.open_orders(symbol: symbol)
    end
    
    # Get all open orders across all symbols
    # @see Resources::Order#all_open_orders
    def all_open_orders
      @order.all_open_orders
    end
    
    # Get account info
    # @see Resources::Account#info
    def account_info
      @account.info
    end
    
    # Get positions
    # @see Resources::Account#positions
    def positions(symbol: nil)
      @account.positions(symbol: symbol)
    end
    
    # Get balances
    # @see Resources::Account#balance
    def balances
      @account.balance
    end
    
    # Get ticker
    # @see Resources::Market#ticker_24h
    def ticker(symbol: nil)
      @market.ticker_24h(symbol: symbol)
    end
    
    # Get klines
    # @see Resources::Market#klines
    def klines(symbol:, interval:, limit: 500)
      @market.klines(symbol: symbol, interval: interval, limit: limit)
    end
    
    # Create algo order
    # @see Resources::AlgoOrder#create
    def create_algo_order(**kwargs)
      @algo_orders.create(**kwargs)
    end
    
    # Get algo orders
    # @see Resources::AlgoOrder#open
    def algo_orders_open(symbol: nil)
      @algo_orders.open(symbol: symbol)
    end
  end
end
