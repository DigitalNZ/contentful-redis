# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::KeyManager, contentful: true do
  context '#attribute_glossary' do
    it 'creates the attribute_glossary key' do
      expect(ContentfulRedis::KeyManager.attribute_glossary(Contentful::Page, :slug)).to eq 'xxx/page/slug'
    end
  end

  context '#content_model_key' do
    let(:klass) { Contentful::Page }
    it 'creates the contentful model response key' do
      expect(
        ContentfulRedis::KeyManager.content_model_key(
          klass.space,
          'preview',
          'sys.id': 'XXXXX', content_type: klass.content_model
        )
      ).to eq 'xxxx/preview/sys.id-XXXXX/content_type-page'
    end
  end
end
