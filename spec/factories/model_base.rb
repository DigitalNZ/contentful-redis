# frozen_string_literal: true

FactoryBot.define do
  factory :contentful_model_base, class: ContentfulRedis::ModelBase do
    initialize_with do
      new('items' => [{ 'sys' => { 'id' => 'xxx' }, 'fields' => [] }])
    end
  end
en:
