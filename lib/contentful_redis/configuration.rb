module ContentfulRedis
  class Configuration
    attr_writer :model_scope
    attr_accessor :spaces, :redis, :default_env

    def model_scope
      return "#{@model_scope}::" if @model_scope != nil

      ''
    end
  end
end
