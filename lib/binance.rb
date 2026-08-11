# frozen_string_literal: true

require 'json'
require 'logger'
require 'zeitwerk'
require 'faraday'
require 'bigdecimal'

# Core files
require_relative 'binance/version'
require_relative 'binance/errors'
require_relative 'binance/constants'

# Core modules
require_relative 'binance/core/endpoint_registry'
require_relative 'binance/core/base_api'
require_relative 'binance/core/base_model'

# Unified entry point for all Binance products (spot, futures, options).
module Binance
  # Environment variable names for API credentials
  ENV_KEYS = { api_key: 'BINANCE_API_KEY', secret_key: 'BINANCE_SECRET_KEY' }.freeze

  # Fallback values when nothing is configured
  DEFAULTS = { testnet: false, recv_window: 5000 }.freeze
  class Error < StandardError; end

  # Configure the Binance client
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

  # Configuration class for Binance client
  class Configuration
    attr_accessor :api_key, :secret_key, :testnet, :logger, :recv_window

    def initialize
      @testnet = false
      @recv_window = 5000
      @logger = nil
    end
  end

  # Create a new API client instance with support for all Binance products
  # @param api_key [String, nil] Binance API key (optional for public data)
  # @param secret_key [String, nil] Binance API secret (optional for public data)
  # @param testnet [Boolean] Use testnet (default: false)
  # @param recv_window [Integer] Receive window in ms (default: 5000)
  # @return [Client] Unified Binance client
  def self.client(api_key: nil, secret_key: nil, testnet: nil, recv_window: nil)
    Client.new(**client_options(api_key: api_key, secret_key: secret_key, testnet: testnet, recv_window: recv_window))
  end

  # Resolve all client options from explicit values, configuration, and environment
  # @return [Hash] Resolved client options
  def self.client_options(api_key: nil, secret_key: nil, testnet: nil, recv_window: nil)
    {
      api_key: resolve(:api_key, api_key),
      secret_key: resolve(:secret_key, secret_key),
      testnet: resolve(:testnet, testnet),
      recv_window: resolve(:recv_window, recv_window)
    }
  end

  # Resolve a single option: explicit value > configuration > environment > default
  # @param key [Symbol] Option key
  # @param explicit [Object, nil] Explicitly passed value
  # @return [Object] Resolved value
  def self.resolve(key, explicit)
    return explicit unless explicit.nil?

    config_value = configuration&.public_send(key)
    return config_value unless config_value.nil?
    return DEFAULTS[key] unless ENV_KEYS.key?(key)

    ENV.fetch(ENV_KEYS[key], nil)
  end
  private_class_method :client_options, :resolve

  # Main unified client providing access to all Binance products
  class Client
    attr_reader :api_key, :secret_key, :testnet, :recv_window, :logger

    # Initialize the unified Binance client
    # @param api_key [String, nil] Binance API key (optional for public-only usage)
    # @param secret_key [String, nil] Binance API secret (optional for public-only usage)
    # @param testnet [Boolean] Use testnet (default: false)
    # @param recv_window [Integer] Receive window in ms (default: 5000)
    # @param logger [Logger] Custom logger (optional)
    def initialize(api_key: nil, secret_key: nil, testnet: false, recv_window: 5000, logger: nil)
      @api_key = api_key
      @secret_key = secret_key
      @testnet = testnet
      @recv_window = recv_window
      @logger = logger || default_logger

      # Validate credentials if provided
      return unless (@api_key && !@secret_key) || (@secret_key && !@api_key)

      raise ArgumentError, 'Both api_key and secret_key must be provided together, or both nil for public data only'
    end

    # Lazy initialization for USD-M Futures module
    # @return [Binance::USDM::API]
    def um_futures
      @um_futures ||= begin
        require_relative 'binance_usdm'
        Binance::USDM::API.new(
          api_key: @api_key,
          secret_key: @secret_key,
          testnet: @testnet,
          logger: @logger
        )
      end
    end

    def spot
      raise NotImplementedError, 'Spot client is planned for a future release'
    end

    def cm_futures
      raise NotImplementedError, 'COIN-M Futures client is planned for a future release'
    end

    def options
      raise NotImplementedError, 'Options client is planned for a future release'
    end

    def margin
      raise NotImplementedError, 'Margin client is planned for a future release'
    end

    def wallet
      raise NotImplementedError, 'Wallet client is planned for a future release'
    end

    def ws
      raise NotImplementedError,
            'Unified WebSocket manager is planned for a future release. ' \
            'Use Binance::USDM::WebSocket::MarketClient for futures streaming.'
    end

    # Synchronize time with Binance server
    # @return [Hash] Server times from each product
    def sync_time!
      results = {}
      begin
        results[:um_futures] = um_futures.sync_time!
      rescue StandardError => e
        @logger.warn("Failed to sync UM Futures time: #{e.message}")
      end
      results
    end

    # Check if client has credentials for signed requests
    # @return [Boolean]
    def authenticated?
      !@api_key.nil? && !@secret_key.nil?
    end

    private

    # Default logger
    # @return [Logger]
    def default_logger
      Logger.new($stdout).tap do |log|
        log.level = ENV.fetch('BINANCE_LOG_LEVEL', 'WARN').to_sym
      end
    end
  end
end
