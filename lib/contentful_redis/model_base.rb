# frozen_string_literal: true

# Base class for contentful redis intergation.
module ContentfulRedis
  class ModelBase
    class << self
      def find(id, env = ContentfulRedis.configuration.default_env || :published)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :get, env).call)
      end

      def find_by(args, env = ContentfulRedis.configuration.default_env || :published)
        raise ContentfulRedis::Error::ArgumentError, "#{args} contain fields which are not a decleared as a searchable fields" unless (args.keys - searchable_fields).empty?

        id = args.values.map do |value|
          key = ContentfulRedis::KeyManager.attribute_glossary(self, value)
          key.present? ? ContentfulRedis.redis.get(key) : nil
        end.compact.first

        raise ContentfulRedis::Error::RecordNotFound, 'Missing attribute in glossary' if id.nil?

        find(id, env)
      end

      def update(id, env = ContentfulRedis.configuration.default_env || :published)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :update, env).call)
      end

      def destroy(id, env = ContentfulRedis.configuration.default_env || :published)
        keys = []
        keys << ContentfulRedis::KeyManager.content_model_key(space, env, 'sys.id': id, content_type: content_model)
        searchable_fields.each do |field|
          keys << ContentfulRedis::KeyManager.attribute_glossary(self, field)
        end

        ContentfulRedis.redis.del(*keys)
      end

      def space
        ContentfulRedis.configuration.spaces.first[1]
      end

      def content_model
        model_name = name.demodulize

        "#{model_name[0].downcase}#{model_name[1..-1]}"
      end

      def searchable_fields
        []
      end

      def define_searchable_fields(*fields)
        instance_eval("def searchable_fields; #{fields}; end")
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

      create_searchable_attribute_links if self.class.searchable_fields.any?
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

    def create_searchable_attribute_links
      self.class.searchable_fields.each do |field|
        begin
          instance_attribute = send(field)
          raise ContentfulRedis::Error::ArgumentError, 'Searchable fields cannot be blank and must be required' if instance_attribute.nil?
          raise ContentfulRedis::Error::ArgumentError, 'Searchable fields must be singular and cannot be references' if instance_attribute.is_a?(Array)

          key = ContentfulRedis::KeyManager.attribute_glossary(self.class, send(field))
          next if ContentfulRedis.redis.exists(key)
          puts "Creating new key #{key}"
          ContentfulRedis.redis.set(key, id)
        rescue NoMethodError => _e
          raise ContentfulRedis::Error::ArgumentError, "Undefined attribute: #{field} when creating attribute glossary"
        end
      end
    end
  end
end
