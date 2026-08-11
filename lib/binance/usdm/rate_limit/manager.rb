# frozen_string_literal: true

require_relative 'bucket'

module Binance
  module USDM
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
          @mutex.synchronize do
            consume_endpoint_limits?(endpoint_spec.metadata)
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
            raise RateLimitError, "Rate limit wait exceeded #{max_wait}s" if elapsed > max_wait

            sleep(0.1)
          end
        end

        # Get current usage statistics
        # @return [Hash] Usage stats
        def usage
          {
            request_weight: bucket_usage(:request_weight),
            orders_10s: bucket_usage(:orders_10s),
            orders_1m: bucket_usage(:orders_1m)
          }
        end

        # Update limits from response headers
        # @param headers [Hash] Response headers
        def update_from_headers(headers)
          headers = headers.transform_keys(&:downcase)

          resync_bucket(headers, 'x-mbx-used-weight-1m', :request_weight)
          resync_bucket(headers, 'x-mbx-order-count-10s', :orders_10s)
          resync_bucket(headers, 'x-mbx-order-count-1m', :orders_1m)
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
            request_weight: build_bucket(:request_weight, limits[:request_weight_1m], 60),
            orders_10s: build_bucket(:orders_10s, limits[:orders_10s], 10),
            orders_1m: build_bucket(:orders_1m, limits[:orders_1m], 60),
            raw_requests: build_bucket(:raw_requests, limits[:raw_requests_1s], 1)
          }
        end

        def build_bucket(name, limit, interval)
          Bucket.new(name: name, limit: limit, interval: interval)
        end

        def consume_endpoint_limits?(metadata)
          return false unless buckets[:request_weight].consume(metadata[:weight] || 1)
          return false unless consume_order_limits?(metadata)
          return false unless buckets[:raw_requests].consume(1)

          true
        end

        def consume_order_limits?(metadata)
          if metadata[:order_count_10s].positive? && !buckets[:orders_10s].consume(metadata[:order_count_10s])
            return false
          end

          return false if metadata[:order_count_1m].positive? && !buckets[:orders_1m].consume(metadata[:order_count_1m])

          true
        end

        def bucket_usage(name)
          {
            remaining: buckets[name].remaining,
            usage: buckets[name].usage
          }
        end

        def resync_bucket(headers, header_name, bucket_name)
          used = headers[header_name]
          return unless used

          buckets[bucket_name].reset
          buckets[bucket_name].consume(used.to_i)
        end
      end
    end
  end
end
