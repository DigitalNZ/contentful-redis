# frozen_string_literal: true

FactoryBot.define do
  factory :contentful_asset, class: ContentfulRedis::Asset do
    initialize_with do
      new(
        'sys' => {
          'type' => 'Asset',
          'id' => 'XXXX'
        },
        'fields' => {
          'title' => 'Asset Title',
          'description' => 'Asset description',
          'file' => {
            'url' => '//images.ctfassets.net/space/XXXX/XXXX/image.jpg',
            'details' => { 'size' => 73_037, 'image' => { 'width' => 1080, 'height' => 1519 } },
            'fileName' => 'image.jpg',
            'contentType' => 'image/jpeg'
          }
        }
      )
    end
  end
end
