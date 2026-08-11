# frozen_string_literal: true

require 'binance_usdm'
require 'binance'
require 'webmock/rspec'
require 'vcr'
require_relative 'helpers/shared_contexts'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Load VCR configuration
  config.before(:suite) do
    VCR.configure do |vcr_config|
      vcr_config.cassette_library_dir = 'spec/vcr_cassettes'
      vcr_config.hook_into :webmock
      vcr_config.configure_rspec_metadata!

      # Allow WebMock stubs when no cassette is active
      vcr_config.allow_http_connections_when_no_cassette = true

      # Filter out sensitive data
      vcr_config.filter_sensitive_data('<BINANCE_API_KEY>') { ENV.fetch('BINANCE_API_KEY', nil) }
      vcr_config.filter_sensitive_data('<BINANCE_SECRET_KEY>') { ENV.fetch('BINANCE_SECRET_KEY', nil) }

      # Match requests by method, host, path, query, and body
      vcr_config.default_cassette_options = {
        match_requests_on: %i[method host path query body],
        record: :once,
        serialize_with: :yaml,
        preserve_exact_body_bytes: true
      }
    end
  end
end
