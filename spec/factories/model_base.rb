# frozen_string_literal: true

FactoryBot.define do
  factory :content_model, class: ContentfulRedis::ModelBase do
    initialize_with do
      new('items' => [{ 'sys' => { 'id' => 'xxx' }, 'fields' => [] }])
    end

    after(:create) do |model, _evaluator|
      model.class.define_searchable_fields :id
    end
  end
end
