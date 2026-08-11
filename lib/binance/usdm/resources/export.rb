# frozen_string_literal: true

require_relative '../core/base_api'

module Binance
  module USDM
    module Resources
      # Async data export endpoints for downloading order/trade/income history.
      # Usage: request a download id, then poll the matching *_download_link
      # method until the returned status is "completed".
      class Export < BaseAPI
        # Request a download id for futures order history
        # @param start_time [Integer] Start time in ms
        # @param end_time [Integer] End time in ms
        # @return [Hash] Download id
        def request_order_download(start_time:, end_time:)
          get('/fapi/v1/order/asyn', params: { startTime: start_time, endTime: end_time })
        end

        # Request a download id for futures trade history
        # @param start_time [Integer] Start time in ms
        # @param end_time [Integer] End time in ms
        # @return [Hash] Download id
        def request_trade_download(start_time:, end_time:)
          get('/fapi/v1/trade/asyn', params: { startTime: start_time, endTime: end_time })
        end

        # Request a download id for futures transaction (income) history
        # @param start_time [Integer] Start time in ms
        # @param end_time [Integer] End time in ms
        # @return [Hash] Download id
        def request_income_download(start_time:, end_time:)
          get('/fapi/v1/income/asyn', params: { startTime: start_time, endTime: end_time })
        end

        # Get the download link for a previously requested order history export
        # @param download_id [String] Download id from #request_order_download
        # @return [Hash] Download link and status
        def order_download_link(download_id:)
          get('/fapi/v1/order/asyn/id', params: { downloadId: download_id })
        end

        # Get the download link for a previously requested trade history export
        # @param download_id [String] Download id from #request_trade_download
        # @return [Hash] Download link and status
        def trade_download_link(download_id:)
          get('/fapi/v1/trade/asyn/id', params: { downloadId: download_id })
        end

        # Get the download link for a previously requested income history export
        # @param download_id [String] Download id from #request_income_download
        # @return [Hash] Download link and status
        def income_download_link(download_id:)
          get('/fapi/v1/income/asyn/id', params: { downloadId: download_id })
        end
      end
    end
  end
end
