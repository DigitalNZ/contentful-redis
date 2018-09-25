# frozen_string_literal: true

ContentfulRedis.configure do |config|
  config.redis = Redis::Store.new(host: (ENV['REDIS_HOST']) || 'localhost', port: 6379, db: 1, namespace: 'contentful')
  config.spaces = {
    test_space: {
      space_id: 'xxxx',
      access_token: 'xxxx',
      preview_access_token: 'xxxx'
    },

    test_space_2: {
      space_id: 'xxxy',
      access_token: 'xxxx',
      preview_access_token: 'xxxx'
    }
  }
end
