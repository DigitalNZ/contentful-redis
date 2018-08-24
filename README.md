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

### Spaces

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

### Redis Store
Set up your redis configuration I recommend that you have a separate Redis database for all of your contentful data which has a namespace
See [redis-store](https://github.com/redis-store/redis-store) for configuration details

### Default env

If unset the defalt call is to the `:published` data. however, setting default_env to `:preview` will request to the preview api.
The Find methods can have an aditional argument to force non default endpoint.

```ruby
ContentfulRedis.configure do |config|
  # if unset defaults to :published
  config.default_env = :preview
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/contentful-redis-rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
