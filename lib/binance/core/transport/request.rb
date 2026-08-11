# frozen_string_literal: true

module Binance
  module Core
    module Transport
      # Represents an HTTP request to the Binance API.
      class Request
        attr_reader :method, :path, :params, :security, :encoding, :metadata

        # Initialize a new request
        # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
        # @param path [String] API endpoint path (e.g., "/fapi/v1/order")
        # @param params [Hash] Request parameters
        # @param security [Symbol, nil] Security type (:trade, :user_data, :market, nil)
        # @param encoding [Symbol] Parameter encoding (:query, :form, :json)
        # @param metadata [Hash] Additional metadata (weight, order_count, etc.)
        def initialize(method:, path:, params: {}, security: nil, encoding: :query, metadata: {})
          @method = method
          @path = path
          @params = params || {}
          @security = security
          @encoding = encoding
          @metadata = metadata
        end

        # Check if request requires signature
        # @return [Boolean]
        def signed?
          %i[trade user_data].include?(security)
        end

        # Check if request needs API key header
        # @return [Boolean]
        def needs_api_key?
          %i[trade user_data market].include?(security)
        end

        # Get HTTP method as string
        # @return [String]
        def method_str
          method.to_s.upcase
        end
      end
    end
  end
end
