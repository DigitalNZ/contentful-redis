# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::KeyManager, contentful: true do
  let!(:test_class) { Page = Class.new(ContentfulRedis::ModelBase) }

  context '#attribute_index' do
    it 'creates the attribute_index key' do
      expect(ContentfulRedis::KeyManager.attribute_index(test_class, :slug)).to eq 'xxxx/page/slug'
    end
  end

  context '#content_model_key' do
    it 'creates the contentful model response key' do
      expect(
        ContentfulRedis::KeyManager.content_model_key(
          test_class.space,
          'preview',
          'sys.id': 'XXXXX', content_type: test_class.content_model
        )
      ).to eq 'xxxx/preview/sys.id-XXXXX/content_type-page'
    end
  end
end
