# frozen_string_literal: true

require_relative 'contentful_redis/configuration'
require_relative 'contentful_redis/model_base'

# Dir["#{Dir.pwd}/lib/contentful_redis/**/*.rb"].each { |f| require f }

module ContentfulRedis
  VERSION = '0.1.1'.freeze

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= ContentfulRedis::Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def redis
      configuration.redis
    end
  end
end
