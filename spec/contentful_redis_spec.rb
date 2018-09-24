# frozen_string_literal: true

RSpec.describe ContentfulRedis do
  it 'has a version number' do
    expect(ContentfulRedis::VERSION).not_to be nil
  end

  describe 'configuration' do
    let(:space_config) do
      {
        test_space: {
          id: 'xxxx',
          access_token: 'xxxx',
          preview_access_token: 'xxxx'
        }
      }
    end

    it 'can configure space information' do
      ContentfulRedis.configure do |config|
        config.spaces = space_config
      end

      expect(ContentfulRedis.configuration.spaces).to eq space_config
    end

    it 'can set the redis database' do
      ContentfulRedis.configure do |config|
        config.redis = Redis::Store.new(
          host: (ENV['REDIS_HOST']) || 'localhost',
          port: 6379,
          db:   1,
          namespace: 'contentful_redis'
        )
      end
      expect(ContentfulRedis.configuration.redis).to be_a(Redis)

      ContentfulRedis.configuration.redis.reconnect
      expect(ContentfulRedis.configuration.redis.connected?).to be true
    end

    it 'can configure content model module' do
      ContentfulRedis.configure do |config|
        config.model_scope = 'Contentful'
      end

      expect(ContentfulRedis.configuration.model_scope).to eq 'Contentful::'
    end

    it 'can configure deeper model modules' do
      ContentfulRedis.configure do |config|
        config.model_scope = 'Contentful::Model'
      end

      expect(ContentfulRedis.configuration.model_scope).to eq 'Contentful::Model::'
    end
  end
end
