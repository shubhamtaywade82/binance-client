# frozen_string_literal: true

require_relative 'bucket'

module Binance
  module Core
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
          @buckets = build_buckets(limits || DEFAULT_LIMITS)
          @mutex = Mutex.new
        end

        # Check if request can be made based on endpoint metadata
        # @param endpoint_spec [Transport::EndpointSpec] Endpoint specification
        # @return [Boolean] true if request allowed, false if would exceed limits
        def allow?(endpoint_spec)
          @mutex.synchronize { allowed_for?(endpoint_spec.metadata) }
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
            raise Binance::RateLimitError, "Rate limit wait exceeded #{max_wait}s" if elapsed > max_wait

            sleep(0.1)
          end
        end

        # Get current usage statistics
        # @return [Hash] Usage stats
        def usage
          %i[request_weight orders_10s orders_1m].to_h do |name|
            [name, bucket_usage(name)]
          end
        end

        # Update limits from response headers
        # @param headers [Hash] Response headers
        def update_from_headers(headers)
          headers = headers.transform_keys(&:downcase)
          sync_bucket(:request_weight, headers['x-mbx-used-weight-1m'])
          sync_bucket(:orders_10s, headers['x-mbx-order-count-10s'])
          sync_bucket(:orders_1m, headers['x-mbx-order-count-1m'])
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

        private

        def build_buckets(limits)
          {
            request_weight: Bucket.new(name: :request_weight, limit: limits[:request_weight_1m], interval: 60),
            orders_10s: Bucket.new(name: :orders_10s, limit: limits[:orders_10s], interval: 10),
            orders_1m: Bucket.new(name: :orders_1m, limit: limits[:orders_1m], interval: 60),
            raw_requests: Bucket.new(name: :raw_requests, limit: limits[:raw_requests_1s], interval: 1)
          }
        end

        def allowed_for?(metadata)
          return false unless buckets[:request_weight].consume(metadata[:weight] || 1)
          return false unless orders_allowed?(metadata)
          return false unless buckets[:raw_requests].consume(1)

          true
        end

        def orders_allowed?(metadata)
          order_count_allowed?(buckets[:orders_10s], metadata[:order_count_10s]) &&
            order_count_allowed?(buckets[:orders_1m], metadata[:order_count_1m])
        end

        def order_count_allowed?(bucket, count)
          count.to_i.positive? ? bucket.consume(count) : true
        end

        def bucket_usage(name)
          bucket = buckets[name]
          { remaining: bucket.remaining, usage: bucket.usage }
        end

        def sync_bucket(name, used)
          return unless used

          buckets[name].reset
          buckets[name].consume(used.to_i)
        end
      end
    end
  end
end
