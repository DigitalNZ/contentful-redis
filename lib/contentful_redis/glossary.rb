# frozen_string_literal: true

# Construct a glossary of attributes which link to their contentful id.
# this allows for `find_by(attribute: '')` without duplicating the redis index
module ContentfulRedis
  class Glossary
    def initialize(klass, attribute)
      @klass = klass
      @attribute = attribute.to_s
    end

    def call
      parameters = { content_type: @klass.content_model, limit: 1000 }

      models = ContentfulRedis::Request.new(@klass.space, parameters).call

      models['items'].map do |entry|
        attr_value = entry.dig('fields', @attribute)

        raise StandardError, "#{@attribute} was not found in entry #{entry.dig('sys', 'id')}" if attr_value.nil?

        key = ContentfulRedis::KeyManager.attribute_glossary(@klass, attr_value)
        entry_id = entry.dig('sys', 'id')
        ContentfulRedis.configuration.redis.set(key, entry_id)

        key
      end
    end
  end
end
