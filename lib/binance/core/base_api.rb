# frozen_string_literal: true

module Binance
  module Core
    # Base class for all API resource classes across all products
    class BaseAPI
      attr_reader :client, :product

      def initialize(client, product:)
        @client = client
        @product = product
      end

      # Execute request using endpoint registry
      def execute(endpoint_name, params = {})
        endpoint_spec = EndpointRegistry.find(product, endpoint_name)
        raise ArgumentError, "Unknown endpoint: #{product}.#{endpoint_name}" unless endpoint_spec

        client.execute(Transport::EndpointSpec.new(**endpoint_spec), params)
      end
    end
  end
end
