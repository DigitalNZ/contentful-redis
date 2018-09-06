# frozen_string_literal: true

# Base class for contentful redis intergation.
module ContentfulRedis
  class ModelBase
    class << self
      def space
        ContentfulRedis.configuration.spaces.first[1]
      end

      def find(id, env = ContentfulRedis.configuration.default_env || :published)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :get, env).call)
      end

      # TODO: Update the supported attributes
      def find_by(args, env = ContentfulRedis.configuration.default_env || :published)
        raise ContentfulRedis::Error::ArgumentError, 'Only support slug option' if args.keys != [:slug]

        id = ContentfulRedis.configuration.redis.get(ContentfulRedis::KeyManager.attribute_glossary(self, args[:slug]))
        raise ContentfulRedis::Error::RecordNotFound, 'Blank ID' if id.nil?

        find(id, env)
      end

      def update(id , env = ContentfulRedis.configuration.default_env || :published)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :update, env).call)
      end

      def content_model
        model_name = name.demodulize

        "#{model_name[0].downcase}#{model_name[1..-1]}"
      end
    end

    def initialize(model)
      instance_variable_set(:@id, model['items'].first.dig('sys', 'id'))
      self.class.send(:attr_reader, :id)

      entries = entries_as_objects(model)

      model['items'].first['fields'].each do |key, value|
        value = case value
                when Array
                  value.map { |val| entries[val.dig('sys', 'id')] || val }
                when Hash
                  extract_object_from_hash(model, value, entries)
                else
                  value
                end

        instance_variable_set("@#{key.underscore}", value)
      end
    end

    def content_type
      self.class.name.demodulize.underscore
    end

    private

    def entries_as_objects(model)
      entries = model.dig('includes', 'Entry')

      return {} if entries.nil? || entries.empty?

      entries.each_with_object({}) do |entry, hash|
        type = entry.dig('sys', 'contentType', 'sys', 'id')
        id = entry.dig('sys', 'id')

        hash[id] = ContentfulRedis::ClassFinder.search(type).find(id)
      end
    end

    def extract_object_from_hash(model, value, entries)
      entry_id = value.dig('sys', 'id')
      asset = model.dig('includes', 'Asset')&.first

      if entries.key?(entry_id)
        entries[entry_id]
      elsif asset.present?
        ContentfulRedis::Asset.new(asset)
      else
        value
      end
    end
  end
end
