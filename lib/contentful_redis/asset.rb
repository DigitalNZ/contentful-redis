# frozen_string_literal: true

module ContentfulRedis
  class Asset
    attr_reader :id, :title, :description, :url, :details, :file_name, :content_type

    def initialize(model)
      @id           = model.dig('sys',    'id')
      @title        = model.dig('fields', 'title')
      @description  = model.dig('fields', 'description')
      @url          = model.dig('fields', 'file', 'url')
      @details      = model.dig('fields', 'file', 'details')
      @file_name    = model.dig('fields', 'file', 'fileName')
      @content_type = model.dig('fields', 'file', 'contentType')
    end
  end
end
