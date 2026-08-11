# frozen_string_literal: true

module Binance
  module USDM
    # Base class for all API resource classes.
    class BaseAPI
      include SignatureHelper

      attr_reader :client

      # Initialize the base API
      # @param client [Client] HTTP client instance
      def initialize(client)
        @client = client
      end

      # Perform GET request
      # @param endpoint [String] API endpoint
      # @param params [Hash] Query parameters
      # @param signed [Boolean] Whether request requires signature
      # @return [Hash, Array] Parsed response
      def get(endpoint, params: {}, signed: true, **kwargs)
        client.get(endpoint, params: params, signed: signed, **kwargs)
      end

      def post(endpoint, params: {}, signed: true, **kwargs)
        client.post(endpoint, params: params, signed: signed, **kwargs)
      end

      def put(endpoint, params: {}, signed: true, **kwargs)
        client.put(endpoint, params: params, signed: signed, **kwargs)
      end

      def delete(endpoint, params: {}, signed: true, **kwargs)
        client.delete(endpoint, params: params, signed: signed, **kwargs)
      end
    end
  end
end
