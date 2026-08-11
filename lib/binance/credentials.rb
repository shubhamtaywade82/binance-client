# frozen_string_literal: true

require 'openssl'

module Binance
  module Credentials
    # Base class for API credentials
    class Base
      attr_reader :api_key, :algorithm

      def initialize(api_key:, algorithm:)
        @api_key = api_key
        @algorithm = algorithm
      end

      def sign(payload)
        raise NotImplementedError, 'Subclasses must implement #sign'
      end
    end

    # HMAC-SHA256 credentials (most common for Binance)
    class HMAC < Base
      attr_reader :secret_key

      def initialize(api_key:, secret_key:)
        super(api_key: api_key, algorithm: :hmac_sha256)
        @secret_key = secret_key
      end

      def sign(payload)
        OpenSSL::HMAC.hexdigest('SHA256', secret_key, payload)
      end
    end

    # RSA credentials (for institutional accounts)
    class RSA < Base
      attr_reader :private_key

      def initialize(api_key:, private_key:)
        super(api_key: api_key, algorithm: :rsa)
        @private_key = case private_key
                       when String
                         OpenSSL::PKey::RSA.new(private_key)
                       when OpenSSL::PKey::RSA
                         private_key
                       else
                         raise ArgumentError, 'private_key must be String or OpenSSL::PKey::RSA'
                       end
      end

      def sign(payload)
        private_key.sign(OpenSSL::Digest::SHA256.new, payload)
      end
    end

    # Ed25519 credentials (emerging support)
    class Ed25519 < Base
      attr_reader :private_key

      def initialize(api_key:, private_key:)
        super(api_key: api_key, algorithm: :ed25519)
        @private_key = case private_key
                       when String
                         if defined?(Ed25519::SigningKey)
                           Ed25519::SigningKey.new([private_key].pack('H*'))
                         else
                           raise RuntimeError, 'Ed25519 gem required for Ed25519 credentials'
                         end
                       when Ed25519::SigningKey
                         private_key
                       else
                         raise ArgumentError, 'private_key must be String (hex) or Ed25519::SigningKey'
                       end
      end

      def sign(payload)
        private_key.sign(payload.unpack('B*').first)
      end
    end
  end
end
