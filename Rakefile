# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
  task.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = 'spec/integration/**/*_spec.rb'
end

RuboCop::RakeTask.new(:lint) do |task|
  # explicit paths keep rubocop from scanning vendor/bundle and tripping on
  # vendored gems' own .rubocop.yml plugin declarations
  task.patterns = ['lib', 'spec', 'binance_usdm.gemspec', 'Rakefile']
  task.options = ['--parallel']
end

desc 'Check dependencies for known security vulnerabilities'
task :audit do
  sh 'bundle exec bundle-audit check --update'
end

desc 'Generate documentation'
task :docs do
  sh 'bundle exec yard doc'
end

desc 'Run full CI check'
task check: %i[lint audit spec build]

task default: :check
