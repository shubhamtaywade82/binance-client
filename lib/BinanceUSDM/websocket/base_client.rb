# frozen_string_literal: true

require "faye/websocket"
require "eventmachine"
require "json"
require "logger"

module BinanceUSDM
  module WebSocket
    # Base WebSocket client for Binance USD-M Futures.
    class BaseClient
      attr_reader :url, :testnet, :logger
      
      # Initialize WebSocket client
      # @param testnet [Boolean] Use testnet (default: false)
      # @param logger [Logger] Custom logger (optional)
      def initialize(testnet: false, logger: nil)
        @testnet = testnet
        @logger = logger || default_logger
        @ws = nil
        @reconnect_attempts = 0
        @max_reconnect_attempts = 5
        @reconnect_delay = 5
        @subscriptions = []
      end
      
      # Start WebSocket connection
      def connect
        EM.run do
          setup_connection
        end
      end
      
      # Stop WebSocket connection
      def disconnect
        @ws.close if @ws
        EM.stop if EM.reactor_running?
      end
      
      # Subscribe to streams
      # @param streams [Array<String>] Stream names (e.g., ["btcusdt@ticker"])
      def subscribe(streams)
        @subscriptions += streams
        send_request("SUBSCRIBE", streams) if connected?
      end
      
      # Unsubscribe from streams
      # @param streams [Array<String>] Stream names
      def unsubscribe(streams)
        @subscriptions -= streams
        send_request("UNSUBSCRIBE", streams) if connected?
      end
      
      # List current subscriptions
      # @return [Array<String>] Subscribed streams
      def list_subscriptions
        send_request("LIST_SUBSCRIPTIONS") if connected?
      end
      
      # Get all market streams
      # @return [Array<String>] All available stream names
      def all_streams
        send_request("GET_ALL_STREAMS") if connected?
      end
      
      private
      
      # Build WebSocket URL
      # @return [String] WebSocket URL
      def build_url
        base = testnet ? Constants::Urls::WEBSOCKET_TESTNET_BASE : Constants::Urls::WEBSOCKET_BASE
        "#{base}/stream"
      end
      
      # Build combined stream URL
      # @return [String] Combined stream URL
      def build_combined_url
        base = testnet ? Constants::Urls::WEBSOCKET_TESTNET_BASE : Constants::Urls::WEBSOCKET_BASE
        streams = @subscriptions.join("/")
        "#{base}/stream?streams=#{streams}"
      end
      
      # Setup WebSocket connection
      def setup_connection
        url = build_combined_url
        
        logger.info("Connecting to #{url}")
        
        @ws = Faye::WebSocket::Client.new(url)
        
        @ws.on(:open) do |event|
          logger.info("WebSocket connected")
          @reconnect_attempts = 0
          on_open(event)
        end
        
        @ws.on(:message) do |event|
          data = JSON.parse(event.data)
          on_message(data)
        rescue JSON::ParserError => e
          logger.error("Failed to parse message: #{e.message}")
        end
        
        @ws.on(:close) do |event|
          logger.warn("WebSocket closed: code=#{event.code} reason=#{event.reason}")
          @ws = nil
          reconnect if should_reconnect?
          on_close(event)
        end
        
        @ws.on(:error) do |event|
          logger.error("WebSocket error: #{event.message}")
          on_error(event)
        end
      end
      
      # Send request over WebSocket
      # @param method [String] Method name
      # @param params [Array, nil] Parameters
      def send_request(method, params = nil)
        return unless connected?
        
        id = SecureRandom.uuid
        message = { method: method, params: params, id: id }
        message[:id] = id
        
        @ws.send(message.to_json)
        logger.debug("Sent: #{message.inspect}")
      end
      
      # Check if connected
      # @return [Boolean]
      def connected?
        !@ws.nil?
      end
      
      # Should attempt reconnect
      # @return [Boolean]
      def should_reconnect?
        @reconnect_attempts < @max_reconnect_attempts
      end
      
      # Reconnect with exponential backoff
      def reconnect
        @reconnect_attempts += 1
        delay = @reconnect_delay * (2 ** (@reconnect_attempts - 1))
        
        logger.info("Reconnecting in #{delay}s (attempt #{@reconnect_attempts}/#{@max_reconnect_attempts})")
        
        EM.add_timer(delay) do
          setup_connection if should_reconnect?
        end
      end
      
      # Callback when connection opens
      # @param event [Event] Open event
      def on_open(event)
        # Override in subclass
      end
      
      # Callback when message received
      # @param data [Hash] Message data
      def on_message(data)
        # Override in subclass
      end
      
      # Callback when connection closes
      # @param event [Event] Close event
      def on_close(event)
        # Override in subclass
      end
      
      # Callback when error occurs
      # @param event [Event] Error event
      def on_error(event)
        # Override in subclass
      end
      
      # Default logger
      # @return [Logger]
      def default_logger
        Logger.new($stdout).tap do |log|
          log.level = ENV.fetch("BINANCE_WS_LOG_LEVEL", "INFO").to_sym
        end
      end
    end
  end
end
