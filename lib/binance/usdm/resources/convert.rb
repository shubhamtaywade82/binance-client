# frozen_string_literal: true

require_relative '../core/base_api'

module Binance
  module USDM
    module Resources
      # Futures Convert (asset-to-asset swap) endpoints.
      class Convert < BaseAPI
        # List all convert pairs
        # @param from_asset [String, nil] Filter by source asset
        # @param to_asset [String, nil] Filter by destination asset
        # @return [Array<Hash>] Convert pairs
        def exchange_info(from_asset: nil, to_asset: nil)
          params = {}
          params[:fromAsset] = from_asset if from_asset
          params[:toAsset] = to_asset if to_asset

          get('/fapi/v1/convert/exchangeInfo', params: params, signed: false)
        end

        # Request a convert quote
        # @param from_asset [String] Source asset
        # @param to_asset [String] Destination asset
        # @param from_amount [String, nil] Amount of from_asset (mutually exclusive with to_amount)
        # @param to_amount [String, nil] Amount of to_asset (mutually exclusive with from_amount)
        # @param valid_time [String, nil] Quote validity: 10s, 30s, 1m, 2m (default: 10s)
        # @return [Hash] Quote with quoteId, ratio, and expiry
        def get_quote(from_asset:, to_asset:, from_amount: nil, to_amount: nil, valid_time: nil)
          raise ArgumentError, 'Either from_amount or to_amount must be provided' unless from_amount || to_amount

          params = { fromAsset: from_asset, toAsset: to_asset }
          params[:fromAmount] = from_amount if from_amount
          params[:toAmount] = to_amount if to_amount
          params[:validTime] = valid_time if valid_time

          post('/fapi/v1/convert/getQuote', params: params)
        end

        # Accept a previously requested quote
        # @param quote_id [String] Quote id from #get_quote
        # @return [Hash] Order id and status
        def accept_quote(quote_id:)
          post('/fapi/v1/convert/acceptQuote', params: { quoteId: quote_id })
        end

        # Get the status of a convert order
        # @param order_id [String, nil] Convert order id
        # @param quote_id [String, nil] Quote id (alternative to order_id)
        # @return [Hash] Order status
        def order_status(order_id: nil, quote_id: nil)
          raise ArgumentError, 'Either order_id or quote_id must be provided' unless order_id || quote_id

          params = {}
          params[:orderId] = order_id if order_id
          params[:quoteId] = quote_id if quote_id

          get('/fapi/v1/convert/orderStatus', params: params)
        end
      end
    end
  end
end
