# frozen_string_literal: true

require_relative 'bucket'

module BinanceUSDM
  module RateLimit
    # Rate limit manager for Binance API.
    class Manager
      attr_reader :buckets

      # Default rate limits for Binance USDⓈ-M Futures
      # See: https://binance-docs.github.io/apidocs/futures/en/#rate-limit
      DEFAULT_LIMITS = {
        request_weight_1m: 2400,
        orders_10s: 50,
        orders_1m: 200,
        raw_requests_1s: 10
      }.freeze

      # Initialize rate limit manager
      # @param limits [Hash] Custom limits (optional, uses defaults if not provided)
      def initialize(limits: nil)
        limits ||= DEFAULT_LIMITS

        @buckets = {
          request_weight: Bucket.new(
            name: :request_weight,
            limit: limits[:request_weight_1m],
            interval: 60
          ),
          orders_10s: Bucket.new(
            name: :orders_10s,
            limit: limits[:orders_10s],
            interval: 10
          ),
          orders_1m: Bucket.new(
            name: :orders_1m,
            limit: limits[:orders_1m],
            interval: 60
          ),
          raw_requests: Bucket.new(
            name: :raw_requests,
            limit: limits[:raw_requests_1s],
            interval: 1
          )
        }

        @mutex = Mutex.new
      end

      # Check if request can be made based on endpoint metadata
      # @param endpoint_spec [Transport::EndpointSpec] Endpoint specification
      # @return [Boolean] true if request allowed, false if would exceed limits
      def allow?(endpoint_spec)
        @mutex.synchronize do
          metadata = endpoint_spec.metadata

          # Check request weight
          weight = metadata[:weight] || 1
          return false unless buckets[:request_weight].consume(weight)

          # Check order count limits
          if metadata[:order_count_10s].positive? && !buckets[:orders_10s].consume(metadata[:order_count_10s])
            return false
          end

          return false if metadata[:order_count_1m].positive? && !buckets[:orders_1m].consume(metadata[:order_count_1m])

          # Check raw request rate
          return false unless buckets[:raw_requests].consume(1)

          true
        end
      end

      # Wait until request can be made
      # @param endpoint_spec [Transport::EndpointSpec] Endpoint specification
      # @param max_wait [Integer] Maximum wait time in seconds (default: 60)
      # @raise [RateLimitError] if max_wait exceeded
      def wait_until_allowed(endpoint_spec, max_wait: 60)
        start_time = Time.now

        loop do
          return if allow?(endpoint_spec)

          elapsed = Time.now - start_time
          raise Errors::RateLimitError, "Rate limit wait exceeded #{max_wait}s" if elapsed > max_wait

          sleep(0.1)
        end
      end

      # Get current usage statistics
      # @return [Hash] Usage stats
      def usage
        {
          request_weight: {
            remaining: buckets[:request_weight].remaining,
            usage: buckets[:request_weight].usage
          },
          orders_10s: {
            remaining: buckets[:orders_10s].remaining,
            usage: buckets[:orders_10s].usage
          },
          orders_1m: {
            remaining: buckets[:orders_1m].remaining,
            usage: buckets[:orders_1m].usage
          }
        }
      end

      # Update limits from response headers
      # @param headers [Hash] Response headers
      def update_from_headers(headers)
        headers = headers.transform_keys(&:downcase)

        if headers['x-mbx-used-weight-1m']
          used = headers['x-mbx-used-weight-1m'].to_i
          # Adjust bucket based on actual usage
          buckets[:request_weight].reset
          buckets[:request_weight].consume(used)
        end

        if headers['x-mbx-order-count-10s']
          used = headers['x-mbx-order-count-10s'].to_i
          buckets[:orders_10s].reset
          buckets[:orders_10s].consume(used)
        end

        return unless headers['x-mbx-order-count-1m']

        used = headers['x-mbx-order-count-1m'].to_i
        buckets[:orders_1m].reset
        buckets[:orders_1m].consume(used)
      end

      # Reset all buckets
      def reset_all
        @mutex.synchronize do
          buckets.each_value(&:reset_all)
        end
      end

      # Check if any bucket is near limit (>80% usage)
      # @return [Boolean]
      def near_limit?
        buckets.any? { |_, bucket| bucket.usage > 0.8 }
      end

      # Get most constrained bucket
      # @return [Bucket, nil]
      def most_constrained_bucket
        buckets.max_by { |_, bucket| bucket.usage }&.last
      end
    end
  end
end
