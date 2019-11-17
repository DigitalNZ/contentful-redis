# frozen_string_literal: true

require File.expand_path("../lib/contentful_redis/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'contentful_redis'
  spec.version       = ContentfulRedis::VERSION
  spec.authors       = ['DanHenton', 'Edwin Rozario']
  spec.email         = ['Dan.Henton@gmail.com']

  spec.summary       = 'Contentful api wrapper which caches responses from contentful'
  spec.homepage      = 'https://github.com/DigitalNZ/contentful-redis'
  spec.license       = 'GNU'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday'
  spec.add_dependency 'redis-store'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'webmock'
end
