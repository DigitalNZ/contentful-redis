# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::Request, contentful: true do
  let(:space) { ContentfulRedis::ModelBase.space }
  let(:request_class) { build(:request) }

  context 'initalize' do
    it "sets it's space" do
      expect(request_class.instance_variable_get('@space')).to eq space
    end

    it "sets it's endpoint" do
      expect(request_class.instance_variable_get('@endpoint')).to eq 'cdn'
    end

    it "sets it's access_token" do
      expect(request_class.instance_variable_get('@access_token')).to eq space[:preview_access_token]
    end

    it "sets it's parameters" do
      expect(request_class.instance_variable_get('@parameters')).to eq("sys.id": 'XXXX', content_type: 'page', include: 1)
    end
  end

  it 'responds with a hashed JSON object' do
    expect(request_class.call).to be_a(Hash)
  end

  it 'it stores the contentful response in redis' do
    expect(ContentfulRedis.configuration.redis.keys).to be_empty

    request_class.call

    expect(ContentfulRedis.configuration.redis.keys.count).to eq 1
    expect(ContentfulRedis.configuration.redis.keys).to include('xxxx/preview/sys.id-xxxx/content_type-page/include-1')
    expect(JSON.parse(ContentfulRedis.configuration.redis.get('xxxx/preview/sys.id-xxxx/content_type-page/include-1'))).to be_a(Hash)
  end

  context 'Exception handling' do
    it 'raises a RecordNotFound error' do
      expect do
        ContentfulRedis::Request.new(space, "sys.id": 'XXXX', content_type: 'page').call
      end.to raise_error ContentfulRedis::Error::RecordNotFound
    end
  end
end
