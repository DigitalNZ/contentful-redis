# frozen_string_literal: true

module ContentfulRedis
  class Configuration
    attr_writer :model_scope
    attr_accessor :spaces, :redis, :default_env, :logging

    def model_scope
      "#{@model_scope}::" unless @model_scope.nil?
    end
  end
end
