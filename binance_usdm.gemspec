# frozen_string_literal: true

require_relative 'lib/BinanceUSDM/version'

Gem::Specification.new do |spec|
  spec.name = 'binance_usdm'
  spec.version = BinanceUSDM::VERSION
  spec.authors = ['Your Name']
  spec.email = ['your.email@example.com']

  spec.summary = 'Ruby SDK for Binance USD-M Futures API'
  spec.description = 'A production-grade Ruby client for Binance USD-M Futures trading. ' \
                     'Provides typed models, REST API access for orders, positions, account management, ' \
                     'market data, and WebSocket streaming for real-time market updates. ' \
                     'Built for algorithmic trading systems and portfolio management tools.'
  spec.homepage = 'https://github.com/yourusername/binance_usdm'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Files shipped in the gem
  spec.files = Dir.glob('{lib,exe}/**/*') + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'eventmachine', '~> 1.2'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faye-websocket', '~> 0.11'
  spec.add_dependency 'logger', '~> 1.5'
  spec.add_dependency 'zeitwerk', '~> 2.6'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
