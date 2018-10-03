# frozen_string_literal: true

require_relative 'asset'
require_relative 'request'
require_relative 'key_manager'
require_relative 'error'
require_relative 'class_finder'

# Base class for contentful redis intergation.
module ContentfulRedis
  class ModelBase
    class << self
      def find(id, env = nil)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :get, request_env(env)).call)
      end

      def find_by(args, env = ContentfulRedis.configuration.default_env || :published)
        raise ContentfulRedis::Error::ArgumentError, "#{args} contain fields which are not a declared as a searchable field" unless (args.keys - searchable_fields).empty?

        id = args.values.map do |value|
          key = ContentfulRedis::KeyManager.attribute_index(self, value)
          key.nil? || key.empty? ? nil : ContentfulRedis.redis.get(key)
        end.compact.first

        raise ContentfulRedis::Error::RecordNotFound, 'Missing attribute in glossary' if id.nil?

        find(id, env)
      end

      def update(id, env = nil)
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :update, request_env(env)).call)
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

      private

      def request_env(env)
        env || ContentfulRedis.configuration.default_env || :published
      end
    end

    def initialize(model)
      instance_variable_set(:@id, model['items'].first.dig('sys', 'id'))
      self.class.send(:attr_reader, :id)

      entries = entries_as_objects(model)

      model['items'].first['fields'].each do |key, value|
        value = case value
                when Array
                  value.map { |val| entries[val.dig('sys', 'id')] }.compact
                when Hash
                  extract_object_from_hash(model, value, entries)
                else
                  value
                end

        instance_variable_set("@#{key.underscore}", value)
      end

      create_searchable_attribute_links if self.class.searchable_fields.any?
    end

    def destroy
      keys = [ContentfulRedis::KeyManager.content_model_key(self.class.space, self.class.send(:request_env, nil),
                                                            'sys.id': id, content_type: content_type, include: 1)]

      self.class.send(:searchable_fields).each do |field|
        keys << ContentfulRedis::KeyManager.attribute_index(self.class, send(field.to_sym))
      end

      ContentfulRedis.redis.del(*keys)
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

      assets = model.dig('includes', 'Asset')
      asset = if !assets.nil? && assets.is_a?(Array)
                model.dig('includes', 'Asset').first
              end

      if entries.key?(entry_id)
        entries[entry_id]
      elsif !asset.nil?
        ContentfulRedis::Asset.new(asset)
      else
        value
      end
    end

    def create_searchable_attribute_links
      self.class.searchable_fields.each do |field|
        begin
          instance_attribute = send(field)
        rescue NoMethodError => _e
          raise ContentfulRedis::Error::ArgumentError, "Undefined attribute: #{field} when creating attribute glossary"
        end

        raise ContentfulRedis::Error::ArgumentError, 'Searchable fields cannot be blank and must be required' if instance_attribute.nil?
        raise ContentfulRedis::Error::ArgumentError, 'Searchable fields must be singular and cannot be references' if instance_attribute.is_a?(Array)

        key = ContentfulRedis::KeyManager.attribute_index(self.class, send(field))
        next if ContentfulRedis.redis.exists(key)

        ContentfulRedis.redis.set(key, id)
      end
    end
  end
end
