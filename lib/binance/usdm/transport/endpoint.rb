# frozen_string_literal: true

module Binance
  module USDM
    module Transport
      # Endpoint specification defining API endpoint behavior.
      class EndpointSpec
        attr_reader :path, :method, :security, :encoding, :metadata

        # Initialize endpoint specification
        # @param path [String] API endpoint path
        # @param method [Symbol] HTTP method
        # @param security [Symbol] Security type (:trade, :user_data, :market, nil)
        # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
        # @param metadata [Hash] Additional metadata (weight, order_count_10s, order_count_1m, ...)
        def initialize(path:, method:, security: :market, encoding: :query, **metadata)
          @path = path
          @method = method
          @security = security
          @encoding = encoding
          @metadata = { weight: 1, order_count_10s: 0, order_count_1m: 0 }.merge(metadata)
        end

        # Create a request from this spec
        # @param params [Hash] Request parameters
        # @return [Request]
        def build_request(params = {})
          Request.new(
            method: method,
            path: path,
            params: params,
            security: security,
            encoding: encoding,
            metadata: metadata
          )
        end

        # Check if endpoint consumes order limits
        # @return [Boolean]
        def consumes_order_limits?
          metadata[:order_count_10s].to_i.positive? || metadata[:order_count_1m].to_i.positive?
        end
      end
    end
  end
end
