# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# faraday-net_http >= 3.1 pulls net-http/uri versions that cannot activate on Ruby 3.0
gem 'faraday-net_http', '~> 3.0.0'
# rubygems loads tsort at boot; Ruby 3.0 ships 0.1.0, newer versions fail activation
gem 'tsort', '0.1.0'

group :development, :test do
  gem 'debug', require: 'debug/prelude'
  gem 'rake', '~> 13.0'
end

group :development do
  gem 'bundler-audit', '~> 0.9'
  gem 'rubocop', '~> 1.64', require: false
  gem 'rubocop-performance', '~> 1.21', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 3.0', require: false
  gem 'yard', '~> 0.9', require: false
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'simplecov', require: false
  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.23'
end
