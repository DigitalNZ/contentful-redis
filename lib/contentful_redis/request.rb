# frozen_string_literal: true

require_relative 'key_manager'
require_relative 'error'

# Request from contentful api and store in redis.
# Atempt to fetch response from redis before requesting to the contentful api
module ContentfulRedis
  class Request
    def initialize(space, params, action = :get, env = ContentfulRedis.configuration.default_env || :published)
      @space = space
      @action = action

      if env.to_s.downcase == 'published'
        @endpoint = 'cdn'
        @access_token = @space[:access_token]
      else
        @endpoint = 'preview'
        @access_token = @space[:preview_access_token]
      end

      params[:include] = 1

      @parameters = params
    end

    def call
      generated_key = ContentfulRedis::KeyManager.content_model_key(@space, @endpoint, @parameters)

      return fetch_from_origin(generated_key) if @action == :update || !ContentfulRedis.redis.exists(generated_key)

      JSON.parse(ContentfulRedis.redis.get(generated_key))
    end

    private

    def fetch_from_origin(generated_key)
      response = perform_request

      raise ContentfulRedis::Error::RecordNotFound, 'Contentful entry was not found' if response.match?(/"total":0/)

      ContentfulRedis.redis.set(generated_key, response)

      JSON.parse(response)
    end

    def perform_request
      res = faraday_connection.get do |req|
        req.url "https://#{@endpoint}.contentful.com/spaces/#{@space[:space_id]}/environments/master/entries"

        req.params = @parameters
      end

      catch_errors(res)

      # decompress then use JSON.parse to remove any blank characters to reduce bytesize
      # Even when we ask for gzip encoding if content model is small contentfull wont gzib the response body
      #
      # Futher storage optimizations can be made to reduce the total redis size.
      begin
        JSON.parse(Zlib::GzipReader.new(StringIO.new(res.body)).read).to_json
      rescue Zlib::GzipFile::Error
        JSON.parse(res.body).to_json
      end
    end

    def faraday_connection
      ::Faraday.new do |faraday|
        faraday.request :url_encoded

        if ContentfulRedis.configuration.logging
          faraday.response :logger do |logger|
            logger.filter(/(Authorization:)(.*)/, '\1[REMOVED]')
          end
        end

        faraday.adapter Faraday.default_adapter
        faraday.headers = {
          'Authorization': "Bearer #{@access_token}",
          'Content-Type': 'application/vnd.contentful.delivery.v1+json',
          'Accept-Encoding': 'gzip'
        }
      end
    end

    def catch_errors(res)
      send("__#{res.status.to_s[0]}00_error__") unless res.status == 200
    end

    def __400_error__
      raise ContentfulRedis::Error::RecordNotFound, 'Contentful could not find the content entry'
    end

    def __500_error__
      raise ContentfulRedis::Error::InternalServerError, 'An external Contentful error has occured'
    end
  end
end
