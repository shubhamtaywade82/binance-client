# frozen_string_literal: true

module BinanceUSDM
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
    def get(endpoint, params: {}, signed: true)
      client.get(endpoint, params: params, signed: signed)
    end
    
    # Perform POST request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature
    # @return [Hash, Array] Parsed response
    def post(endpoint, params: {}, signed: true)
      client.post(endpoint, params: params, signed: signed)
    end
    
    # Perform PUT request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Request body
    # @param signed [Boolean] Whether request requires signature
    # @return [Hash, Array] Parsed response
    def put(endpoint, params: {}, signed: true)
      client.put(endpoint, params: params, signed: signed)
    end
    
    # Perform DELETE request
    # @param endpoint [String] API endpoint
    # @param params [Hash] Query parameters
    # @param signed [Boolean] Whether request requires signature
    # @return [Hash, Array] Parsed response
    def delete(endpoint, params: {}, signed: true)
      client.delete(endpoint, params: params, signed: signed)
    end
  end
end
