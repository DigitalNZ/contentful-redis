# frozen_string_literal: true

FactoryBot.define do
  factory :contentful_redis_request, class: ContentfulRedis::Request do
    initialize_with do
      new(ContentfulRedis::ModelBase.space, "sys.id": 'XXXX', content_type: 'page')
    end
  end
end
