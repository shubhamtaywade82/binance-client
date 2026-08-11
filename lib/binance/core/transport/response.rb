# frozen_string_literal: true

module Binance
  module Core
    module Transport
      # Represents an HTTP response from the Binance API.
      class Response
        attr_reader :status, :body, :headers, :request_id, :rate_limits

        # Initialize a new response
        # @param status [Integer] HTTP status code
        # @param body [Hash, Array] Parsed JSON body
        # @param headers [Hash] Response headers
        def initialize(status:, body:, headers: {})
          @status = status
          @body = body
          @headers = (headers || {}).transform_keys(&:downcase)
          @request_id = headers['X-MBX-REQUEST-ID'] || headers['x-mbx-request-id']
          @rate_limits = extract_rate_limits
        end

        # Extract rate limit information from headers
        # @return [Hash] Rate limit data
        def extract_rate_limits
          {
            request_weight_1m: headers['x-mbx-used-weight-1m']&.to_i,
            order_count_10s: headers['x-mbx-order-count-10s']&.to_i,
            order_count_1m: headers['x-mbx-order-count-1m']&.to_i,
            retry_after: headers['retry-after']&.to_i
          }.compact
        end

        # Check if response is successful
        # @return [Boolean]
        def success?
          status >= 200 && status < 300
        end
      end
    end
  end
end
