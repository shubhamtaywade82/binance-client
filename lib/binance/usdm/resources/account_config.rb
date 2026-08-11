# frozen_string_literal: true

require_relative '../core/base_api'

module Binance
  module USDM
    module Resources
      # Account configuration, trading status, and reporting endpoints.
      # Complements Account (which covers positions, margin, balances, leverage).
      class AccountConfig < BaseAPI
        # Get account information (V3)
        # @return [Hash] Account details
        def account
          get('/fapi/v3/account', params: {})
        end

        # Get account balance (V3)
        # @return [Array<Hash>] Account balances
        def balance
          get('/fapi/v3/balance', params: {})
        end

        # Get position information (V3)
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @return [Array<Hash>] Positions
        def position_risk(symbol: nil)
          params = symbol ? { symbol: symbol } : {}
          get('/fapi/v3/positionRisk', params: params)
        end

        # Get futures account configuration (fee tier, leverage caps, etc.)
        # @return [Hash] Account configuration
        def account_config
          get('/fapi/v1/accountConfig', params: {})
        end

        # Get futures trading quantitative rules indicators
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @return [Hash] Trading status indicators
        def api_trading_status(symbol: nil)
          params = symbol ? { symbol: symbol } : {}
          get('/fapi/v1/apiTradingStatus', params: params)
        end

        # Get BNB fee burn status
        # @return [Hash] Fee burn status
        def fee_burn_status
          get('/fapi/v1/feeBurn', params: {})
        end

        # Toggle BNB fee burn on trades
        # @param enabled [Boolean] true to burn fees in BNB, false to disable
        # @return [Hash] Response
        def set_fee_burn(enabled:)
          post('/fapi/v1/feeBurn', params: { feeBurn: enabled ? 'true' : 'false' })
        end

        # Get current multi-assets margin mode
        # @return [Hash] Multi-assets mode status
        def multi_assets_margin
          get('/fapi/v1/multiAssetsMargin', params: {})
        end

        # Change multi-assets margin mode
        # @param enabled [Boolean] true for Multi-Assets Mode, false for Single-Asset Mode
        # @return [Hash] Response
        def set_multi_assets_margin(enabled:)
          post('/fapi/v1/multiAssetsMargin', params: { multiAssetsMargin: enabled ? 'true' : 'false' })
        end

        # Get current order rate limit usage
        # @return [Array<Hash>] Rate limit usage
        def rate_limit_order
          get('/fapi/v1/rateLimit/order', params: {})
        end

        # Get symbol configuration (margin type, leverage, etc.)
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @return [Array<Hash>] Symbol configuration
        def symbol_config(symbol: nil)
          params = symbol ? { symbol: symbol } : {}
          get('/fapi/v1/symbolConfig', params: params)
        end

        # Get Classic Portfolio Margin account information
        # @param asset [String] Asset (e.g., "USDT")
        # @return [Hash] Portfolio margin account info
        def pm_account_info(asset:)
          get('/fapi/v1/pmAccountInfo', params: { asset: asset })
        end

        # Get position ADL (Auto-Deleverage) quantile estimation
        # @param symbol [String, nil] Trading symbol (optional, all symbols if not provided)
        # @return [Hash, Array<Hash>] ADL quantile
        def adl_quantile(symbol: nil)
          params = symbol ? { symbol: symbol } : {}
          get('/fapi/v1/adlQuantile', params: params)
        end
      end
    end
  end
end
