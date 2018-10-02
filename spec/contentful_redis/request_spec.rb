# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::Request, contentful: true do
  let(:space) { ContentfulRedis::ModelBase.space }
  let(:request_class) { build(:request) }

  before do
    stub_request(:get, 'https://cdn.contentful.com/spaces/xxxx/environments/master/entries?content_type=page&include=1&sys.id=XXXX')
      .to_return(status: 200, body: build(:request, :as_response).to_json, headers: {})
  end

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

  it 'stores the contentful response in redis' do
    expect(ContentfulRedis.redis.keys).to be_empty

    request_class.call

    expect(ContentfulRedis.redis.keys).to include('xxxx/cdn/sys.id-XXXX/content_type-page/include-1')
  end

  context 'update' do
    let(:update_request) { build(:request, :update) }

    it 'will refresh its cache via an update action' do
      ContentfulRedis.redis.set('xxxx/cdn/sys.id-XXXX/content_type-page/include-1', { test: 'case' }.to_json)

      update_request.call

      expect(ContentfulRedis.redis.get('xxxx/cdn/sys.id-XXXX/content_type-page/include-1')).to eq build(:request, :as_response).to_json
    end
  end

  context 'overwriting defaults' do
    let(:preview_request) { build(:request, :preview) }

    it 'the default_env configuration endpoint can be over written' do
      stub_request(:get, 'https://preview.contentful.com/spaces/xxxx/environments/master/entries?content_type=page&include=1&sys.id=XXXX')
        .to_return(status: 200, body: build(:request, :as_response).to_json, headers: {})

      expect(preview_request.call).to eq build(:request, :as_response)
      expect(ContentfulRedis.redis.get('xxxx/preview/sys.id-XXXX/content_type-page/include-1')).to eq build(:request, :as_response).to_json
    end
  end

  context 'Exception handling' do
    it 'raises a RecordNotFound error' do
      stub_request(:get, 'https://cdn.contentful.com/spaces/xxxx/environments/master/entries?content_type=page&include=1&sys.id=not-a-record')
        .to_return(
          status: 404,
          body: {
            "sys": {
              "type": 'Error',
              "id": 'NotFound'
            },
            "message": 'The resource could not be found.',
            "details": {
              "type": 'Space',
              "id": 'xxxx'
            }
          }.to_json,
          headers: {}
        )
      expect do
        ContentfulRedis::Request.new(space, "sys.id": 'not-a-record', content_type: 'page').call
      end.to raise_error ContentfulRedis::Error::RecordNotFound
    end

    it 'raises a RecordNotFound error' do
      stub_request(:get, 'https://cdn.contentful.com/spaces/xxxx/environments/master/entries?content_type=page&include=1&sys.id=not-a-record')
        .to_return(
          status: 500,
          body: {
            "sys": {
              "type": 'Error',
              "id": 'Internal'
            },
            "message": 'Something went wrong',
            "details": {
              "type": 'Space',
              "id": 'xxxx'
            }
          }.to_json,
          headers: {}
        )
      expect do
        ContentfulRedis::Request.new(space, "sys.id": 'not-a-record', content_type: 'page').call
      end.to raise_error ContentfulRedis::Error::InternalServerError
    end
  end
end
