# ContentfulRedis
A lightweight read-only contentful API wrapper which caches your responses in Redis.

# Features
- Lightweight easy to configure ruby contentful integration.
- Faster load times due to having a Redis cache.
- All content models responses are cached.
- Webhooks update
- Multiple space support
- Preview and production API support on a single environment

## WIP
- logger
- Experiment Redis size optimization
- auto clean up of dead Redis keys
- code clean up

ContentfulRedis also supports multiple API endpoints(preview and published) within a single application.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'redis-store' # optional
gem 'contentful_redis'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install contentful_redis

## Configuration

Heres a default example, however, I will go over all of the individual configurations options below

```ruby
# config/initializers/contentful_redis.rb
ContentfulRedis.configure do |config|
  config.default_env = :preview # unless production env
  config.model_scope = 'Contentful' # models live in a Contentful module
  config.logging = true

  config.spaces = { 
    test_space: {
      id: 'xxxx',
      access_token: 'xxxx',
      preview_access_token: 'xxxx'
    }
  }

  config.redis = Redis::Store.new(
    host: (ENV['REDIS_HOST']) || 'localhost',
    port: 6379,
    db: 1,
    namespace: 'contentful'
  )

```

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

To use a different space for a model override the classes `#space` method

```ruby
# app/models/my_model.rb
class MyModel < ContentfulRedis::ModelBase
  
  # override default space
  def self.space
    ContentfulRedis.configuration.spaces[:test_space_2]
  end
end
```

### Redis (required)
There are various ways you can integrate with Redis.
I suggest using [redis-store](https://github.com/redis-store/redis-store) unless your application already has Redis adapter installed.
I recommend having a separate Redis database for all of your contentful data so that you can isolate your application Redis from your content.

```ruby
# config/initializers/contentful_redis.rb
ContentfulRedis.configure do |config|
  config.redis = Redis::Store.new(
    host: (ENV['REDIS_HOST']) || 'localhost',
    port: 6379,
    db: 1,
    namespace: 'contentful'
  )
end
```

### Default env

If unset the default call is to the `:published` data. however, setting default_env to `:preview` will request to the preview API.
The Find methods can have an additional argument to force the non-default endpoint.

```ruby
# config/initializers/contentful_redis.rb
ContentfulRedis.configure do |config|
  # if unset defaults to :published
  config.default_env = :preview
end
```

### Model scope
Set the scope for where your models live.

```ruby
# config/initializers/contentful_redis.rb
ContentfulRedis.configure do |config|
  config.model_scope = 'Contentful'
end

# app/models/contentful/page.rb
module Contentful
  class Page < ContentfulRedis::ModelBase

  end
end
```

## Models
All content models will need to be defined, prior to integration especially when using references.
The example model we are going to define has a slug(input field) and a body(references other content models)

```ruby
# app/models/page.rb
class Page < ContentfulRedis::ModelBase
  # allows the field to be queried from
  define_searchable_fields :slug

  # Set default readers which can return nil
  attr_reader: :slug
  
  # define your desired return types manually
  def body
    @body || []
  end
end
```

### Querying
All content models are found by their contentful ID. Contentful Redis only stores only one cache of the content model
This Redis key is generated and is unique to a content model, space and endpoint.

In these examples within my application I have created a class called `Contentful::Page`

```ruby
  Contentful::Page.find('<contentful_uid>')
```

Contentful Redis does not store a duplicate object from searchable attributes,
Instead, it builds a glossary of searchable attributes mapping to their content models ids.
These attributes are defined in the class declaration as `define_searchable_fields :slug`

```ruby
  Contentful::Page.find_by(slug: 'about-us') 
```

### Deleting
An entry is done by calling destroy on a ContentfulRedis model object or destroy by passing id. This will delete all the redis keys, find and search keys for the entry.

In these examples within my application I have created a class called `Contentful::Page`

```ruby
  Contentful::Page.destroy('<contentful_uid>')
```

or

```ruby
  page = Contentful::Page.find('<contentful_uid>')
  page.destroy
```

### Query optimization
There are three optimizations that can be made on a query.
Due to the nature of content trees and Contentful's references, we need to be able to control which references to follow.

In these examples within my application I have created a class called `Contentful::Page`

#### Only
Fetch all selected reference(s)

```ruby
  # Content model which has child references called descendants
  Contentful::Page.find('<contentful_uid>', only: :descendants)
  Contentful::Page.find_by(slug: '<contentful_slug>', options: { only: :descendants } )

  # Supports Arrays as well
  Contentful::Page.find('<contentful_uid>', only: [:descendants])
  Contentful::Page.find_by(slug: '<contentful_slug>', options: { only: [:descendants] } )
```

#### Except
Fetch all references except the targeted field(s)

```ruby
  # Content model which has many references including child references called descendants

  Contentful::Page.find('<contentful_uid>', except: :descendants)
  Contentful::Page.find_by(slug: <contentful_slug>, options: { except: :descendants } )

  # Supports Arrays as well
  Contentful::Page.find('<contentful_uid>', except: [:descendants])
  Contentful::Page.find_by(slug: <contentful_slug>, options: { except: [:descendants] } )
```

#### Depth
Limit the reference traversal depth.
The value is the amount of edges which to travese down.

```ruby
  Contentful::Page.find(<contentful_uid>, depth: 1 )
  Contentful::Page.find_by(slug: <contentful_slug>, options: { depth: 1 })
```

### Content model overriding

Classes should match their content model name, however, if they don't you can override the classes `#name` method.

```ruby
# app/models/page.rb
class Page < ContentfulRedis::ModelBase

  # Overwrite to match contentful model using ruby class syntax
  def self.name
    'NameThatMatchesContentfulModel'
  end
end
```

## Webhooks

Instead of creating rails specific implementation it is up to the developers to create your controllers and manage your webhook into your applications.
See the [Contentful webhooks docs](https://www.contentful.com/developers/docs/concepts/webhooks/) creating your own

These are the setings which we have found to work the best
We do need need any of the assests as they are handled by contentfuls image server.

### Staging / UAT Update Settings
|              | Create | Save | Autosave | Archive | Unarchive | Publish | Unpublish | Delete |
|--------------|--------|------|----------|---------|-----------|---------|-----------|--------|
| Content Type |        | ✔︎    |          |         |           | ✔︎       |           |        |
| Entry        |        | ✔︎    | ✔︎        |         | ✔︎         | ✔︎       |           |        |
| Asset        |        |      |          |         |           |         |           |        |
|              |        |      |          |         |           |         |           |        |

### Staging / UAT Update Delete
|              | Create | Save | Autosave | Archive | Unarchive | Publish | Unpublish | Delete |
|--------------|--------|------|----------|---------|-----------|---------|-----------|--------|
| Content Type |        |      |          |         |           |         |           | ✔︎      |
| Entry        |        |      |          | ✔︎       |           |         |           | ✔︎      |
| Asset        |        |      |          |         |           |         |           |        |
|              |        |      |          |         |           |         |           |        |


### Production Update Settings
|              | Create | Save | Autosave | Archive | Unarchive | Publish | Unpublish | Delete |
|--------------|--------|------|----------|---------|-----------|---------|-----------|--------|
| Content Type |        |      |          |         |           | ✔︎       |           |        |
| Entry        |        |      |          |         |           | ✔︎       |           |        |
| Asset        |        |      |          |         |           |         |           |        |
|              |        |      |          |         |           |         |           |        |

### Production Delete Settings
|              | Create | Save | Autosave | Archive | Unarchive | Publish | Unpublish | Delete |
|--------------|--------|------|----------|---------|-----------|---------|-----------|--------|
| Content Type |        |      |          |         |           |         | ✔︎         | ✔︎      |
| Entry        |        |      |          | ✔︎       |           |         | ✔︎         | ✔︎      |
| Asset        |        |      |          |         |           |         |           |        |
|              |        |      |          |         |           |         |           |        |

Required Contentful webhooks to update the Redis cache are:
```json
{
  "id": "{ /payload/sys/id }",
  "environment": "{ /payload/sys/environment/sys/id }",
  "model": "{ /payload/sys/contentType/sys/id }"
}
```

When pushing text attributes make sure you are using the correct language endpoint.
```json
{
  "title": "{ /payload/fields/title/en-US }",
  "slug": "{ /payload/fields/slug/en-US }",
}
```

### Webhook Controllers

#### Rails
```ruby
# app/controllers/contentful/webhook_controller.rb
module Contentful
  class WebhookController < ApplicationController
    # before_action :some_auth_layer

    def update
      payload = JSON.parse request.raw_post
      
      contentful_model = ContentfulRedis::ClassFinder.search(payload['model'])
      contentful_model.update(payload['id'])

      render json: { status: :ok }
    end

    def delete
      payload = JSON.parse request.raw_post
      
      contentful_model = ContentfulRedis::ClassFinder.search(payload['model'])
      contentful_model.destroy(payload['id'])

      render json: { status: :ok }
    end
  end
end

# config/routes
#...
namespace :contentful do
  resource 'webhooks', only: :update, :delete
end
# ...
```

#### Other
Feel free to create a PR for other ruby frameworks :)

## Content Seeding
Seeding the data is a great way to get started in building your content models, there is a couple of ways this can be done.

Create a service object inside your application and get it to fetch the root pages of your content tree by their ID.
The find method will build your Redis cache as well as link your content models with their searchable fields.

```ruby
# app/services/seed_content.rb
class SeedContent
  # trigger a cascading content model seeding process
  def call
    ['xxContentfulModelIdxx'].each do |page|
      Contentful::Page.find(page)
    end
  end
end
```

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a Git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/contentful-redis.

## License

The gem is available as open source under the terms of the [GNU General Public License](https://www.gnu.org/licenses/#GPL)
