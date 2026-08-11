# frozen_string_literal: true

require_relative 'base_client'
require 'json'

module Binance
  module USDM
    module WebSocket
      # Private User Data Stream client for order and position updates.
      class UserDataClient < BaseClient
        REFRESH_INTERVAL = 1800 # 30 minutes in seconds

        EVENT_HANDLERS = {
          'ORDER_TRADE_UPDATE' => [:on_order_update, 'o'],
          'ACCOUNT_UPDATE' => [:on_account_update, 'a'],
          'ACCOUNT_CONFIG_UPDATE' => [:on_config_update, 'ac']
        }.freeze

        attr_reader :client, :listen_key
        attr_accessor :on_order_update, :on_account_update, :on_config_update

        # Initialize User Data Stream client
        # @param client [Binance::USDM::Client] API client with valid credentials
        # @param testnet [Boolean] Use testnet (defaults to client.testnet)
        # @param logger [Logger] Logger instance
        def initialize(client:, testnet: nil, logger: nil)
          @client = client
          super(testnet: testnet.nil? ? client.testnet : testnet, logger: logger || client.logger)
          @listen_key = nil
          @keep_alive_timer = nil
        end

        # Start User Data Stream with automated ListenKey lifecycle
        def connect
          ensure_listen_key
          start_keep_alive_timer
          super
        end

        # Disconnect stream and close ListenKey
        def disconnect
          stop_keep_alive_timer
          client.account.close_listen_key(@listen_key) if @listen_key
          @listen_key = nil
          super
        end

        private

        # Obtain or refresh ListenKey
        def ensure_listen_key
          response = client.account.create_listen_key
          @listen_key = response['listenKey']
          logger.info("User Data Stream listenKey acquired: #{@listen_key}")
        rescue StandardError => e
          logger.error("Failed to obtain listenKey: #{e.message}")
          raise
        end

        # Periodic keep-alive to prevent 60-minute ListenKey expiry
        def start_keep_alive_timer
          stop_keep_alive_timer
          EM.next_tick do
            @keep_alive_timer = EM.add_periodic_timer(REFRESH_INTERVAL) do
              keep_alive_listen_key
            end
          end
        end

        def stop_keep_alive_timer
          @keep_alive_timer&.cancel
          @keep_alive_timer = nil
        end

        def keep_alive_listen_key
          return unless @listen_key

          client.account.keep_alive_listen_key(@listen_key)
          logger.debug("Refreshed ListenKey: #{@listen_key}")
        rescue StandardError => e
          logger.warn("Failed to refresh ListenKey: #{e.message}")
        end

        # Build WebSocket URL for user data stream
        def build_combined_url
          base = testnet ? Constants::Urls::WEBSOCKET_TESTNET_BASE : Constants::Urls::WEBSOCKET_BASE
          "#{base}/ws/#{@listen_key}"
        end

        # Handle incoming private WebSocket events
        def on_message(data)
          handler = EVENT_HANDLERS[data['e']]
          return dispatch_event(handler, data) if handler

          return handle_expired_listen_key if data['e'] == 'listenKeyExpired'

          logger.debug("User stream event: #{data.inspect}")
        end

        # Invoke registered callback with event payload
        def dispatch_event(handler, data)
          callback, payload_key = handler
          public_send(callback)&.call(data[payload_key] || data)
        end

        # Refresh ListenKey after expiry
        def handle_expired_listen_key
          logger.warn('ListenKey expired. Re-authenticating...')
          ensure_listen_key
        end
      end
    end
  end
end
