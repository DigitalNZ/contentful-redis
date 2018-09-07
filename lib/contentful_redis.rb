# frozen_string_literal: true

Dir["#{Dir.pwd}/lib/contentful_redis/**/*.rb"].each { |f| require f }

module ContentfulRedis
  VERSION = '0.0.1'

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
