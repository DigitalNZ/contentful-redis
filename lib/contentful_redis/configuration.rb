module ContentfulRedis
  class Configuration
    attr_writer :model_module
    attr_accessor :spaces, :redis, :default_env

    def model_module
      return "#{@model_module}::" if @model_module != nil

      nil
    end
  end
end
