# frozen_string_literal: true

module Binance
  module Core
    # Shared runtime context for all Binance API clients
    # Provides unified configuration, transport, and infrastructure
    class Context
      attr_reader :credentials, :environment, :clock, :recv_window,
                  :rate_limiter, :transport, :logger, :endpoint_registry

      def initialize(credentials:, environment: :production, recv_window: 5000,
                     logger: nil, services: {})
        @credentials = credentials
        @environment = environment
        @recv_window = recv_window
        @logger = logger || default_logger
        @clock = services[:clock] || Clock.new
        @rate_limiter = services[:rate_limiter] || RateLimit::Manager.new
        @transport = services[:transport] || build_transport(credentials, environment, logger)
        @endpoint_registry = services[:endpoint_registry] || EndpointRegistry
      end

      def server_time
        clock.now
      end

      def time_offset
        clock.time_offset
      end

      def sync_time!
        server_time_ms = fetch_server_time
        clock.sync(server_time_ms)
        logger.info("Time synchronized: offset=#{clock.offset_str}")
        server_time_ms
      end

      def authenticated?
        !credentials.nil?
      end

      private

      def fetch_server_time
        response = transport.execute(
          Transport::Request.new(method: :get, path: '/fapi/v1/time', security: :market, encoding: :query)
        )
        response.body['serverTime']
      end

      def build_transport(credentials, environment, logger)
        Transport::HTTP.new(
          base_url: base_url_for(environment),
          api_key: credentials&.api_key,
          secret_key: extract_secret(credentials),
          timeout: 30,
          logger: logger
        )
      end

      def base_url_for(env)
        case env
        when :testnet
          Binance::Constants::Urls::UM_FUTURES_TESTNET_REST_API_BASE
        when :production
          Binance::Constants::Urls::UM_FUTURES_REST_API_BASE
        else
          raise ArgumentError, "Unknown environment: #{env}"
        end
      end

      def extract_secret(creds)
        creds.respond_to?(:secret_key) ? creds.secret_key : nil
      end

      def default_logger
        Logger.new($stdout).tap do |log|
          log.level = ENV.fetch('BINANCE_LOG_LEVEL', 'WARN').to_sym
        end
      end
    end
  end
end
