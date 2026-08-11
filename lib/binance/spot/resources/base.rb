# frozen_string_literal: true

module Binance
  module Spot
    module Resources
      # Shared constructor for all Spot resource classes; each wraps a
      # Binance::Products::API(product: :spot) instance for transport/auth/rate concerns.
      class Base
        def initialize(api)
          @api = api
        end
      end
    end
  end
end
