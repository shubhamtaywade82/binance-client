# frozen_string_literal: true

require "openssl"
require "digest"
require "uri"
require "time"

module BinanceUSDM
  # Helper module for API request signing and parameter formatting.
  module SignatureHelper
    extend self
    
    # Generate HMAC SHA256 signature for Binance API
    # @param secret_key [String] API secret key
    # @param query_string [String] URL-encoded query string to sign
    # @return [String] Hex-encoded signature
    def generate_signature(secret_key, query_string)
      OpenSSL::HMAC.hexdigest("SHA256", secret_key, query_string)
    end
    
    # Get current timestamp in milliseconds
    # @return [Integer] Current time in ms
    def timestamp
      (Time.now.to_f * 1000).to_i
    end
    
    # Build signed query string with timestamp and signature (legacy method)
    # @deprecated Use build_signed_query_for_transport instead
    # @param params [Hash] Request parameters
    # @param api_key [String] API key
    # @param secret_key [String] API secret
    # @param recv_window [Integer] Receive window in ms (default: 5000)
    # @return [String] URL-encoded signed query string
    def build_signed_query(params, api_key, secret_key, recv_window = 5000)
      params = params.dup
      params[:timestamp] = timestamp
      params[:recvWindow] = recv_window if recv_window
      params[:apiKey] = api_key
      
      query_string = URI.encode_www_form(params)
      signature = generate_signature(secret_key, query_string)
      
      "#{query_string}&signature=#{signature}"
    end
    
    # Build signed query string for transport layer (corrected implementation)
    # API key is NOT included in the signed query - it goes in headers
    # @param params [Hash] Request parameters (excluding apiKey)
    # @param api_key [String] API key (used for validation only)
    # @param secret_key [String] API secret
    # @param timestamp [Integer] Timestamp in ms (optional, uses current time if nil)
    # @param recv_window [Integer] Receive window in ms (default: 5000)
    # @return [String] URL-encoded signed query string
    def build_signed_query_for_transport(params, api_key, secret_key, timestamp: nil, recv_window: 5000)
      params = params.dup
      params[:timestamp] = timestamp || self.timestamp
      params[:recvWindow] = recv_window if recv_window && recv_window > 0
      
      # Format params but DO NOT include apiKey in the query string
      formatted_params = format_params(params)
      query_string = URI.encode_www_form(formatted_params)
      
      # Sign the query string (without apiKey)
      signature = generate_signature(secret_key, query_string)
      
      "#{query_string}&signature=#{signature}"
    end
    
    # Format parameters for API request
    # @param params [Hash] Parameters to format
    # @return [Hash] Formatted parameters with camelCase keys
    def format_params(params)
      return {} if params.nil? || params.empty?
      
      params.transform_keys { |key| to_camel_case(key) }
            .compact
            .transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
    end
    
    private
    
    # Convert snake_case to camelCase
    # @param key [Symbol, String] Key to convert
    # @return [String] camelCase string
    def to_camel_case(key)
      key.to_s.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
    end
  end
end
