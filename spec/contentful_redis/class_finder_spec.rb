# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContentfulRedis::ClassFinder do
  it 'finds a defined content model class' do
    TempModel = Class.new(ContentfulRedis::ModelBase)

    expect(ContentfulRedis::ClassFinder.search('temp_model')).to eq TempModel
  end

  it 'finds a scoped content model class' do
    ContentfulRedis::TempModel = Class.new(ContentfulRedis::ModelBase)

    ContentfulRedis.configuration.model_scope = 'ContentfulRedis'

    expect(ContentfulRedis::ClassFinder.search('temp_model')).to eq ContentfulRedis::TempModel
  end

  it 'raises a ClassNotFound error when a unknown contentful class is referenced' do
    expect { ContentfulRedis::ClassFinder.search('unknownType') }.to raise_error ContentfulRedis::Error::ClassNotFound
  end
end
