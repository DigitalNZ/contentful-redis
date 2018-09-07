# frozen_string_literal: true

module ContentfulRedis
  class Configuration
    # TODO: logger

    attr_writer :model_scope
    attr_accessor :spaces, :redis, :default_env

    def model_scope
      return "#{@model_scope}::" unless @model_scope.nil?

      ''
    end
  end
end
