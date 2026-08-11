# frozen_string_literal: true

require_relative '../products/api'
require_relative 'resources/order'
require_relative 'resources/account'
require_relative 'resources/market'

module Binance
  module Spot
    # Typed, ergonomic Spot client. Wraps Binance::Products::API(product: :spot)
    # for transport/auth/testnet handling and exposes resource objects with
    # keyword-argument methods and typed Models instead of raw catalog actions.
    class Client
      attr_reader :api, :order, :account, :market

      def initialize(api_key: nil, secret_key: nil, testnet: false, logger: nil)
        @api = Products::API.new(product: :spot, api_key: api_key, secret_key: secret_key,
                                 testnet: testnet, logger: logger)
        @order = Resources::Order.new(@api)
        @account = Resources::Account.new(@api)
        @market = Resources::Market.new(@api)
      end

      # Synchronize time with Binance server
      # @return [Integer] Server time in milliseconds
      def sync_time!
        @api.sync_time!
      end

      # Check if the client has credentials for signed requests
      # @return [Boolean]
      def authenticated?
        @api.authenticated?
      end
    end
  end
end
