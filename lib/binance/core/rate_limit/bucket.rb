# frozen_string_literal: true

module Binance
  module Core
    # Rate limit bucket for tracking API usage.
    class Bucket
      attr_reader :name, :limit, :interval, :counters

      # Initialize rate limit bucket
      # @param name [Symbol] Bucket name
      # @param limit [Integer] Maximum allowed requests
      # @param interval [Integer] Interval in seconds
      def initialize(name:, limit:, interval:)
        @name = name
        @limit = limit
        @interval = interval
        @counters = {}
        @mutex = Mutex.new
      end

      # Consume from bucket
      # @param amount [Integer] Amount to consume
      # @param key [Symbol] Counter key (default: :default)
      # @return [Boolean] true if consumption successful, false if would exceed limit
      def consume(amount = 1, key: :default)
        @mutex.synchronize do
          counter = get_or_create_counter(key)

          return false if counter[:current] + amount > limit

          counter[:current] += amount
          counter[:last_update] = Time.now
          true
        end
      end

      # Get remaining capacity
      # @param key [Symbol] Counter key (default: :default)
      # @return [Integer] Remaining capacity
      def remaining(key: :default)
        @mutex.synchronize do
          counter = get_or_create_counter(key)
          [0, limit - counter[:current]].max
        end
      end

      # Get usage percentage
      # @param key [Symbol] Counter key (default: :default)
      # @return [Float] Usage percentage (0.0-1.0)
      def usage(key: :default)
        @mutex.synchronize do
          counter = get_or_create_counter(key)
          counter[:current].to_f / limit
        end
      end

      # Reset counter
      # @param key [Symbol] Counter key (default: :default)
      def reset(key: :default)
        @mutex.synchronize do
          counters.delete(key)
        end
      end

      # Reset all counters
      def reset_all
        @mutex.synchronize do
          counters.clear
        end
      end

      # Check if limit exceeded
      # @param key [Symbol] Counter key (default: :default)
      # @return [Boolean]
      def exceeded?(key: :default)
        @mutex.synchronize do
          counter = get_or_create_counter(key)
          counter[:current] >= limit
        end
      end

      private

      # Get or create counter
      # @param key [Symbol] Counter key
      # @return [Hash] Counter hash
      def get_or_create_counter(key)
        counters[key] ||= { current: 0, last_update: Time.now }

        # Auto-reset if interval passed
        counters[key] = { current: 0, last_update: Time.now } if Time.now - counters[key][:last_update] > interval

        counters[key]
      end
    end
  end
end
