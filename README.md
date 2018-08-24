# ContentfulRedis
A light weight read only contentful api wrapper which caches your responses in redis.

ContentfulRedis also supports multiple api endpoints(preview and published) within a single application.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'redis-store'
gem 'contentful-redis-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install contentful-redis-rb

## Configuration

### Spaces (required)
Contentful Redis supports multiple space configurations with your first space being the default

```ruby
# config/initializers/contentful_redis.rb
ContentfulRedis.configure do |config|
  config.spaces = { 
    test_space: {
      id: 'xxxx',
      access_token: 'xxxx',
      preview_access_token: 'xxxx'
    },

    test_space_2: {
      id: 'xxxy',
      access_token: 'xxxx',
      preview_access_token: 'xxxx'
    }
  }
```

To use a different space for a model set overwrite the space class level method in the model

```ruby
# app/models/my_model.rb
class MyModel < ContentfulRedis::ModelBase
  def self.space
    ContentfulRedis.configuration.spaces[:test_space_2]
  end
end
```

The model will connect to your 

### Redis Store (required)
Set up your redis configuration I recommend that you have a separate Redis database for all of your contentful data which has a namespace
See [redis-store](https://github.com/redis-store/redis-store) for configuration details

```ruby
config.redis = Redis::Store.new(
  host: (ENV['REDIS_HOST']) || 'localhost',
  port: 6379,
  db: 1,
  namespace: 'contentful'
)
```

### Default env

If unset the defalt call is to the `:published` data. however, setting default_env to `:preview` will request to the preview api.
The Find methods can have an aditional argument to force non default endpoint.

```ruby
ContentfulRedis.configure do |config|
  # if unset defaults to :published
  config.default_env = :preview
end
```

## Webhooks

Instead of creating rails specific implementation it is up to the developers to create your controllers and manage your webhook into your applications.

See the [Contentful webhooks docs](https://www.contentful.com/developers/docs/concepts/webhooks/) creating your own

Examples bellow will get you started!

### Rails
```ruby
# app/controllers/contentful/webhook_controller.rb
module Contentful
  class WebhookController < ApplicationController
    # before_action :some_auth_layer

    def update
      payload = JSON.parse request.raw_post
      
      # TODO: Confirm method
      <DynamicContentModel>.update(payload.fetch('id'))
    end
  end
end

# config/routes
post 'contentful/webhooks/update', as: :webhook_update
```

### Other
Feel free to create a PR for other ruby frameworks :)

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/contentful-redis-rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
