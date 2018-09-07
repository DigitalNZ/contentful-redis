# frozen_string_literal: true

module ContentfulRedis
  module ClassFinder
    def self.search(type)
      begin
        "#{ContentfulRedis.configuration.model_scope}#{type.classify}".constantize
      rescue NameError => _e
        raise ContentfulRedis::Error::ClassNotFound, "Content type: #{type} is undefined"
      end
    end
  end
end
