# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    initialize_with do
      new('items' => [{ 'sys' => { 'id' => 'xxx' }, 'fields' => [] }])
    end
  end
end
