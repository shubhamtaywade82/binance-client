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
        
        client.execute(
          Transport::EndpointSpec.new(
            path: endpoint_spec[:path],
            method: endpoint_spec[:method],
            security: endpoint_spec[:security],
            encoding: endpoint_spec[:encoding],
            weight: endpoint_spec[:weight] || 1,
            order_count_10s: endpoint_spec[:order_count_10s] || 0,
            order_count_1m: endpoint_spec[:order_count_1m] || 0
          ),
          params
        )
      end
    end
  end
end
