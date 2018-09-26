# frozen_string_literal: true

FactoryBot.define do
  factory :request, class: ContentfulRedis::Request do
    initialize_with do
      new({ space_id: 'xxxx', access_token: 'xxxx', preview_access_token: 'xxxx' }, "sys.id": 'XXXX', content_type: 'page')
    end

    trait :update do
      initialize_with do
        new({ space_id: 'xxxx', access_token: 'xxxx', preview_access_token: 'xxxx' }, { "sys.id": 'XXXX', content_type: 'page' }, :update)
      end
    end

    trait :preview do
      initialize_with do
        new({ space_id: 'xxxx', access_token: 'xxxx', preview_access_token: 'xxxx' }, { "sys.id": 'XXXX', content_type: 'page' }, :get, :preview)
      end
    end

    trait :as_response do
      initialize_with do
        {
          'sys' => { 'type' => 'Array' },
          'total' => 1,
          'skip' => 0,
          'limit' => 100,
          'items' =>
          [
            { 'sys' =>
             { 'space' => { 'sys' => { 'type' => 'Link', 'linkType' => 'Space', 'id' => 'xxxx' } },
               'type' => 'Entry',
               'id' => 'xxx',
               'contentType' => { 'sys' => { 'type' => 'Link', 'linkType' => 'ContentType', 'id' => 'page' } },
               'revision' => 0,
               'createdAt' => '2018-07-02T00:04:52.356Z',
               'updatedAt' => '2018-09-23T23:58:00.071Z',
               'environment' => { 'sys' => { 'id' => 'master', 'type' => 'Link', 'linkType' => 'Environment' } },
               'locale' => 'en-NZ' },
              'fields' => { 'title' => 'Test Page', 'slug' => 'test-page' } }
          ]
        }
      end
    end
  end
end
