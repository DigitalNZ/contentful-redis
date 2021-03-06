# frozen_string_literal: true

require 'bundler/setup'
require 'contentful_redis'
require 'pry'
require 'faraday'
require 'webmock/rspec'
require 'redis-store'

require 'support/factory_bot'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ContentfulRedis.redis.flushdb
  end
end
