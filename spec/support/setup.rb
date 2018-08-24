ContentfulRedis.configure do |config|
  config.redis = Redis::Store.new(host: (ENV['REDIS_HOST']) || 'localhost', port: 6379, db: 1, namespace: 'contentful')
  config.spaces = {}
  config.model_module = 'Contentful'
end
