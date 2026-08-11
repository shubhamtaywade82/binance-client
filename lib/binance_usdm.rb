# frozen_string_literal: true

require "json"
require "logger"
require "zeitwerk"
require "faraday"

# Core files
require_relative "BinanceUSDM/version"
require_relative "BinanceUSDM/errors"
require_relative "BinanceUSDM/constants"

# Helpers
require_relative "BinanceUSDM/helpers/signature_helper"

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
    attr_accessor :api_key, :secret_key, :testnet, :logger
    
    def initialize
      @testnet = false
      @logger = nil
    end
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
  
  # Main API class providing access to all resources
  class API
    attr_reader :client, :order, :account, :market, :ws
    
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
      @ws = WebSocket::MarketClient.new(testnet: testnet, logger: logger)
    end
    
    # Convenience methods delegating to resources
    
    # Place a new order
    # @see Resources::Order#place
    def place_order(**kwargs)
      @order.place(**kwargs)
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
  end
end
