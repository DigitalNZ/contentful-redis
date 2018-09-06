require 'spec_helper'

RSpec.describe ContentfulRedis::ClassFinder do
  it 'finds a defined content model class'
  it 'finds a scoped content model class'
  it 'raises a ClassNotFound error when a unknown contentful class is referenced' do
    expect { ContentfulRedis::ClassFinder.search('unknownType') }.to raise_error ContentfulRedis::Error::ClassNotFound
  end
end
