# frozen_string_literal: true

require_relative 'asset'
require_relative 'request'
require_relative 'key_manager'
require_relative 'error'
require_relative 'class_finder'

# Base class for contentful redis intergation.
module ContentfulRedis
  class ModelBase
    attr_accessor :id

    class << self
      def all(options = {})
        parameters = { content_type: content_model }
        response = ContentfulRedis::Request.new(space, parameters, :get, request_env(options[:env])).call
        sanitised_response = response['items'].map { |resp| { 'items' => [resp] } }
        sanitised_response.map { |sr| [new(sr, options)] }.flatten
      end

      def find(id, options = {})
        raise ContentfulRedis::Error::ArgumentError, 'Expected Contentful model ID' unless id.is_a?(String)

        parameters = { 'sys.id': id, content_type: content_model }
        new(ContentfulRedis::Request.new(space, parameters, :get, request_env(options[:env])).call, options)
      end

      def find_by(args = {})
        unless (args.keys - [searchable_fields, :options].flatten).empty?
          raise ContentfulRedis::Error::ArgumentError, "#{args} contain fields which are not a declared as a searchable field"
        end

        id = args.values.map do |value|
          key = ContentfulRedis::KeyManager.attribute_index(self, value)
          key.nil? || key.empty? ? nil : ContentfulRedis.redis.get(key)
        end.compact.first

        raise ContentfulRedis::Error::RecordNotFound, 'Missing attribute in glossary' if id.nil?

        find(id, args.fetch(:options, {}))
      end

      def update(id, options = {})
        parameters = { 'sys.id': id, content_type: content_model }

        new(ContentfulRedis::Request.new(space, parameters, :update, request_env(options[:env])).call)
      end

      def destroy(id, options = {})
        find(id, env: request_env(options[:env])).destroy
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

    def initialize(model, options = {})
      @id = model['items'].first.dig('sys', 'id')

      entries = entries_as_objects(model, options)

      model['items'].first['fields'].each do |key, value|
        value = case value
                when Array
                  # Construct the referenced entries
                  # They will not apear in the entries hash the attribute has been filtered out
                  value.map { |val| entries[val.dig('sys', 'id')] }.compact
                when Hash
                  extract_object_from_hash(model, value, entries)
                else
                  value
                end

        instance_variable_set("@#{key.underscore}", value) unless value.nil?
      end

      create_searchable_attribute_links if self.class.searchable_fields.any?
    end

    def destroy
      keys = [
        ContentfulRedis::KeyManager.content_model_key(
          self.class.space,
          endpoint,
          'sys.id': id,
          content_type: self.class.content_model,
          include: 1
        )
      ]

      self.class.send(:searchable_fields).each do |field|
        keys << ContentfulRedis::KeyManager.attribute_index(self.class, send(field.to_sym))
      end

      ContentfulRedis.redis.del(*keys)
    end

    def content_type
      self.class.name.demodulize.underscore
    end

    private

    def endpoint
      env = self.class.send(:request_env, nil)

      env.to_s.downcase == 'published' ? 'cdn' : 'preview'
    end

    def entries_as_objects(model, options)
      entries = model.dig('includes', 'Entry')
      return {} if entries.nil? || entries.empty? || (!options[:depth].nil? && options[:depth].zero?)

      organised_id_types = organise_id_types(model)
      options[:depth] = options[:depth].pred unless options[:depth].nil?

      entries.each_with_object({}) do |entry, hash|
        type = entry.dig('sys', 'contentType', 'sys', 'id')
        id = entry.dig('sys', 'id')
        attribute = organised_id_types[id]

        next unless allow?(attribute, options)

        # Catch references to deleted or archived content.
        begin
          hash[id] = ContentfulRedis::ClassFinder.search(type).find(id, options)
        rescue ContentfulRedis::Error::RecordNotFound => _e
          next
        end
      end.compact
    end

    def organise_id_types(model)
      model.dig('items').first['fields'].each_with_object({}) do |(field, value), hash|
        case value
        when Array
          value.each { |v| hash[v.dig('sys', 'id')] = field }
        when Hash
          hash[value.dig('sys', 'id')] = field
        end
      end
    end

    def extract_object_from_hash(model, value, entries)
      entry_id = value.dig('sys', 'id')

      assets = model.dig('includes', 'Asset')
      asset = assets.first if !assets.nil? && assets.is_a?(Array)

      if entries.key?(entry_id)
        entries[entry_id]
      elsif !asset.nil?
        ContentfulRedis::Asset.new(asset)
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

    def allow?(attribute, options)
      only?(attribute, options) && expect?(attribute, options)
    end

    def only?(attribute, options)
      unless options[:only].nil?
        return false unless [options[:only]].flatten.any? do |filter|
          matching_attributes?(attribute, filter)
        end
      end

      true
    end

    def expect?(attribute, options)
      unless options[:except].nil?
        return false if [options[:except]].flatten.any? do |filter|
          matching_attributes?(attribute, filter)
        end
      end

      true
    end

    # Parse the ids to the same string format.
    # contentfulAttribute == ruby_attribute
    def matching_attributes?(attribute, filter)
      attribute.to_s.downcase == filter.to_s.delete('_').downcase
    end
  end
end
