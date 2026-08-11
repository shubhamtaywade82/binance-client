# frozen_string_literal: true

require 'openssl'
require 'digest'
require 'uri'
require 'time'
require 'base64'

module Binance
  # Helper module for API request signing and parameter formatting.
  module SignatureHelper
    extend self

    # Generate signature for Binance API (supports HMAC, RSA, Ed25519)
    # @param secret_or_key [String, OpenSSL::PKey::PKey] Secret or private key
    # @param query_string [String] URL-encoded query string to sign
    # @param algorithm [Symbol] :hmac, :rsa, :ed25519, or :auto
    # @return [String] Signature string (hex for HMAC, Base64 for RSA/Ed25519)
    def generate_signature(secret_or_key, query_string, algorithm: :auto)
      algo = algorithm == :auto ? detect_algorithm(secret_or_key) : algorithm

      case algo
      when :rsa
        sign_rsa(secret_or_key, query_string)
      when :ed25519
        sign_ed25519(secret_or_key, query_string)
      else
        OpenSSL::HMAC.hexdigest('SHA256', secret_or_key.to_s, query_string)
      end
    end

    # Get current timestamp in milliseconds
    # @return [Integer] Current time in ms
    def timestamp
      (Time.now.to_f * 1000).to_i
    end

    # Build signed query string with timestamp and signature (legacy method)
    # @deprecated Use build_signed_query_for_transport instead
    def build_signed_query(params, api_key, secret_key, recv_window = 5000)
      build_signed_query_for_transport(params, api_key, secret_key, recv_window: recv_window)
    end

    # Build signed query string for transport layer (corrected implementation)
    # API key is NOT included in the signed query - it goes in headers
    # @param params [Hash] Request parameters (excluding apiKey)
    # @param api_key [String] API key (used for validation only)
    # @param secret_key [String] API secret
    # @param timestamp [Integer] Timestamp in ms (optional, uses current time if nil)
    # @param recv_window [Integer] Receive window in ms (default: 5000)
    # @return [String] URL-encoded signed query string
    def build_signed_query_for_transport(params, _api_key, secret_key, timestamp: nil, recv_window: 5000)
      params = params.dup
      params[:timestamp] = timestamp || self.timestamp
      params[:recvWindow] = recv_window if recv_window&.positive?

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

      params.transform_keys { |key| to_camel_case(key) }.compact.transform_values { |v| format_value(v) }
    end

    private

    def format_value(value)
      case value
      when Symbol then value.to_s
      when TrueClass then 'true'
      when FalseClass then 'false'
      else value
      end
    end

    def detect_algorithm(key)
      key_str = key.to_s
      return :ed25519 if key_str.include?('ED25519')
      return :rsa if key_str.include?('PRIVATE KEY') || key.is_a?(OpenSSL::PKey::RSA)

      :hmac
    end

    def sign_rsa(private_key, data)
      pkey = private_key.is_a?(OpenSSL::PKey::RSA) ? private_key : OpenSSL::PKey::RSA.new(private_key)
      Base64.strict_encode64(pkey.sign(OpenSSL::Digest.new('SHA256'), data))
    end

    def sign_ed25519(private_key, data)
      pkey = private_key.is_a?(OpenSSL::PKey::PKey) ? private_key : OpenSSL::PKey.read(private_key)
      Base64.strict_encode64(pkey.sign(nil, data))
    end

    # Convert snake_case to camelCase
    # @param key [Symbol, String] Key to convert
    # @return [String] camelCase string
    def to_camel_case(key)
      key.to_s.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
    end
  end
end
