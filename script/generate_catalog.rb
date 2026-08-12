# frozen_string_literal: true

# Generates lib/binance/core/catalog.rb from docs/endpoints.json.
#
# The docs are downloaded from https://developers.binance.com/en/docs/llms.txt
# (API Reference section). Run: bundle exec ruby script/generate_catalog.rb

require 'json'

MANIFEST = {
  'Spot REST API' => { product: :spot, host: 'https://api.binance.com', testnet_host: 'https://testnet.binance.vision',
                       time_path: '/api/v3/time' },
  'Futures (USDⓈ-M) REST API' => { product: :um_futures, host: 'https://fapi.binance.com',
                                   testnet_host: 'https://testnet.binancefuture.com', time_path: '/fapi/v1/time' },
  'Futures (COIN-M) REST API' => { product: :cm_futures, host: 'https://dapi.binance.com',
                                   testnet_host: 'https://testnet.binancefuture.com', time_path: '/dapi/v1/time' },
  'Options REST API' => { product: :options, host: 'https://eapi.binance.com',
                          testnet_host: 'https://testnet.binanceoptions.com', time_path: '/eapi/v1/time' },
  'Portfolio Margin REST API' => { product: :portfolio_margin, host: 'https://papi.binance.com',
                                   testnet_host: 'https://testnet.binancefuture.com', time_path: nil },
  'Portfolio Margin Pro REST API' => { product: :portfolio_margin_pro, host: 'https://api.binance.com',
                                       time_path: '/api/v3/time' },
  'Wallet REST API' => { product: :wallet, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Margin REST API' => { product: :margin, host: 'https://api.binance.com',
                         testnet_host: 'https://testnet.binance.vision', time_path: '/api/v3/time' },
  'Sub Account REST API' => { product: :sub_account, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Simple Earn REST API' => { product: :simple_earn, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Staking REST API' => { product: :staking, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Convert REST API' => { product: :convert, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Binance Pay REST API' => { product: :pay, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Fiat REST API' => { product: :fiat, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'C2C REST API' => { product: :c2c, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Gift Card REST API' => { product: :gift_card, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Mining REST API' => { product: :mining, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Rebate REST API' => { product: :rebate, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Algo Trading REST API' => { product: :algo, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Crypto Loan REST API' => { product: :crypto_loan, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'VIP Loan REST API' => { product: :vip_loan, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'VIP Service REST API' => { product: :vip_service, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'VIP CAAS REST API' => { product: :vip_caas, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Institutional Loan REST API' => { product: :institutional_loan, host: 'https://api.binance.com',
                                     time_path: '/api/v3/time' },
  'Discount Buy REST API' => { product: :discount_buy, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Dual Investment REST API' => { product: :dual_investment, host: 'https://api.binance.com',
                                  time_path: '/api/v3/time' },
  'Exchange Link REST API' => { product: :exchange_link, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Fund Account REST API' => { product: :fund_account, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Link and Trade REST API' => { product: :link_trade, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Link Plus REST API' => { product: :link_plus, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Spot Block Matching REST API' => { product: :block_matching, host: 'https://api.binance.com',
                                      time_path: '/api/v3/time' },
  'Prediction Trading REST API' => { product: :prediction, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Stocks Trading REST API' => { product: :stocks, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Copy Trading REST API' => { product: :copy_trading, host: 'https://api.binance.com', time_path: '/api/v3/time' },
  'Alpha Trading REST API' => { product: :alpha, host: 'https://api.binance.com', time_path: nil },
  'KYC SaaS REST API' => { product: :kyc, host: 'https://api.binance.com', time_path: nil }
}.freeze

# Paths hosted on a different host than the product default (Link and Trade spans hosts).
HOST_OVERRIDES = {
  '/fapi' => 'https://fapi.binance.com',
  '/papi' => 'https://papi.binance.com',
  '/dapi' => 'https://dapi.binance.com',
  '/eapi' => 'https://eapi.binance.com'
}.freeze

SECURITY_MAP = {
  'NONE' => :none,
  'MARKET_DATA' => :market,
  'TRADE' => :trade,
  'USER_DATA' => :user_data,
  'USER_STREAM' => :user_stream,
  'MARGIN' => :trade
}.freeze

def snake(path)
  path.gsub(%r{^/}, '').gsub(/[^a-zA-Z0-9]+/, '_').downcase
end

def action_name(method, path)
  "#{method.downcase}_#{snake(path)}"
end

def resolve_host(family, path)
  prefix = path[%r{^/[a-z]+}]
  return HOST_OVERRIDES[prefix] if HOST_OVERRIDES.key?(prefix)

  MANIFEST.fetch(family)[:host]
end

rows = JSON.parse(File.read('docs/endpoints.json'))
catalog = Hash.new { |h, k| h[k] = [] }
conflicts = []

rows.each do |row|
  family = row['family']
  meta = MANIFEST[family]
  raise "Unknown family: #{family}" unless meta

  action = action_name(row['method'], row['path'])
  entry = {
    action: action,
    method: row['method'].downcase.to_sym,
    path: row['path'],
    security: SECURITY_MAP.fetch(row['security']),
    host: resolve_host(family, row['path']),
    description: row['description']
  }
  conflicts << "#{meta[:product]}.#{action}" if catalog[meta[:product]].any? { |e| e[:action] == action }
  catalog[meta[:product]] << entry
end

unless conflicts.empty?
  warn "Duplicate actions: #{conflicts.uniq.join(', ')}"
  exit 1
end

lines = []
lines << '# frozen_string_literal: true'
lines << ''
lines << '# Generated by script/generate_catalog.rb from docs/endpoints.json.'
lines << '# Source: https://developers.binance.com/en/docs/llms.txt (API Reference).'
lines << '# Do not edit by hand — regenerate with: bundle exec ruby script/generate_catalog.rb'
lines << ''
lines << 'module Binance'
lines << '  module Core'
lines << '    module Catalog'
lines << '      # Endpoint catalog for all Binance REST API families.'
lines << '      # Keyed by product, each entry: action, method, path, security, host, description.'
lines << '      ENDPOINTS = {'

catalog.keys.sort.each do |product|
  entries = catalog[product]
  lines << "        #{product}: ["
  entries.each do |e|
    lines << "          { action: :#{e[:action]}, method: :#{e[:method]}, path: '#{e[:path]}', " \
             "security: :#{e[:security]}, host: '#{e[:host]}', " \
             "description: #{e[:description].inspect} },"
  end
  lines << '        ],'
end

lines << '      }.freeze'
lines << ''
lines << '      # Product metadata: hosts and time-sync path.'
lines << '      PRODUCTS = {'
MANIFEST.keys.sort.each do |family|
  meta = MANIFEST[family]
  testnet = meta[:testnet_host] ? ", testnet_host: '#{meta[:testnet_host]}'" : ''
  lines << "        #{meta[:product]}: { family: #{family.inspect}, host: '#{meta[:host]}', " \
           "time_path: #{meta[:time_path].inspect}#{testnet} },"
end
lines << '      }.freeze'
lines << ''
lines << '      class << self'
lines << '        # Find an endpoint by product and action'
lines << '        # @param product [Symbol] Product key (e.g. :spot)'
lines << '        # @param action [Symbol] Action key (e.g. :get_api_v3_ping)'
lines << '        # @return [Hash, nil] Endpoint spec or nil'
lines << '        def find(product, action)'
lines << '          ENDPOINTS[product]&.find { |e| e[:action] == action }'
lines << '        end'
lines << ''
lines << '        # Get all endpoints for a product'
lines << '        # @param product [Symbol] Product key'
lines << '        # @return [Array<Hash>] Endpoint specs'
lines << '        def for_product(product)'
lines << '          ENDPOINTS.fetch(product, [])'
lines << '        end'
lines << ''
lines << '        # Check if an action exists for a product'
lines << '        # @param product [Symbol] Product key'
lines << '        # @param action [Symbol] Action key'
lines << '        # @return [Boolean]'
lines << '        def exists?(product, action)'
lines << '          !find(product, action).nil?'
lines << '        end'
lines << ''
lines << '        # Get metadata for a product'
lines << '        # @param product [Symbol] Product key'
lines << '        # @return [Hash, nil] Product metadata'
lines << '        def product_metadata(product)'
lines << '          PRODUCTS[product]'
lines << '        end'
lines << '      end'
lines << '    end'
lines << '  end'
lines << 'end'
lines << ''

File.write('lib/binance/core/catalog.rb', lines.join("\n"))

total = catalog.values.sum(&:size)
puts "Generated lib/binance/core/catalog.rb: #{catalog.size} products, #{total} endpoints"
