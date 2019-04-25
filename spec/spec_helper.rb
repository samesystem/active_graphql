# frozen_string_literal: true

require 'bundler/setup'

require 'simplecov'

SimpleCov.start do
  add_filter(/_spec.rb\Z/)
  add_filter(%r{/spec/support/*+})
end

require 'active_graphql'

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'webmock/rspec'
WebMock.disable_net_connect!

Dir['spec/support/**/*.rb'].each { |f| require_relative "../#{f}" }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
