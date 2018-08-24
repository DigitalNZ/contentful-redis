# frozen_string_literal: true

module ContentfulRedis
  module KeyManager
    class << self
      # Links a contentful models attribute to its contentful_id
      def attribute_glossary(klass, attribute)
        "#{klass.space.fetch(:space_id)}/#{klass.content_model}/#{attribute}"
      end

      # Links content model request to its contentful json response
      def content_model_key(space, endpoint, parameters)
        "#{space.fetch(:space_id)}/#{endpoint}/#{parameters.map { |k, v| "#{k}-#{v}" }.join('/')}"
      end
    end
  end
end
