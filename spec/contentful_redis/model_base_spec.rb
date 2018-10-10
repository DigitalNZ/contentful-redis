# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::ModelBase, contentful: true do
  subject { build(:content_model) }

  context 'class level methods' do
    describe '#request_env' do
      it 'defaults to production if the env has not been set' do
        ContentfulRedis.configure do |config|
          config.default_env = nil
        end

        expect(ContentfulRedis::ModelBase.send(:request_env, nil)).to eq :published
      end

      it 'returns the contentful redis configuration value' do
        ContentfulRedis.configure do |config|
          config.default_env = :preview
        end

        expect(ContentfulRedis::ModelBase.send(:request_env, nil)).to eq ContentfulRedis.configuration.default_env
      end

      it 'can be overwritten to return the optinal env query parameter' do
        ContentfulRedis.configure do |config|
          config.default_env = :published
        end

        expect(ContentfulRedis::ModelBase.send(:request_env, :preview)).to eq :preview
      end
    end

    describe '#find(id)' do
      let(:expected_params) { [{ access_token: 'xxxx', preview_access_token: 'xxxx', space_id: 'xxxx' }, { content_type: 'modelBase', "sys.id": 'xxx' }, :get, :published] }

      it 'can query by id' do
        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.find('xxx')
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq 'xxx'
        expect(model.instance_variable_get('@title')).to eq 'Test Page'
        expect(model.instance_variable_get('@slug')).to eq 'test-page'
      end

      it 'the default_env configuration endpoint can be over written' do
        expected_params[-1] = :preview

        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.find('xxx', :preview)
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq 'xxx'
        expect(model.instance_variable_get('@title')).to eq 'Test Page'
        expect(model.instance_variable_get('@slug')).to eq 'test-page'
      end
    end

    describe '#find_by' do
      let(:expected_params) { [{ access_token: 'xxxx', preview_access_token: 'xxxx', space_id: 'xxxx' }, { content_type: 'modelBase', "sys.id": 'xxx' }, :get, :published] }
      let(:glossary_key) { 'xxxx/modelBase/xxx' }

      before do
        ContentfulRedis::ModelBase.define_searchable_fields :id
        ContentfulRedis.redis.set(glossary_key, build(:content_model).id)
      end

      it 'can query by searchable attribute' do
        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.find_by(id: 'xxx')
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq 'xxx'
        expect(model.instance_variable_get('@title')).to eq 'Test Page'
        expect(model.instance_variable_get('@slug')).to eq 'test-page'
      end

      it 'the default_env configuration endpoint can be over written' do
        expected_params[-1] = :preview
        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.find_by({ id: 'xxx' }, :preview)
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq 'xxx'
        expect(model.instance_variable_get('@title')).to eq 'Test Page'
        expect(model.instance_variable_get('@slug')).to eq 'test-page'
      end

      it 'throws an error when the query attribute is not a searchable attribute' do
        expect { ContentfulRedis::ModelBase.find_by(slug: 'xxx') }.to raise_error ContentfulRedis::Error::ArgumentError
      end

      after do
        ContentfulRedis::ModelBase.define_searchable_fields
        ContentfulRedis.redis.del(glossary_key)
      end
    end

    describe '#update(id)' do
      let(:expected_params) { [{ access_token: 'xxxx', preview_access_token: 'xxxx', space_id: 'xxxx' }, { content_type: 'modelBase', "sys.id": 'xxx' }, :update, :published] }

      it 'can trigger a redis update' do
        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.update(subject.id)
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq subject.id
        expect(model.instance_variable_get('@title')).to eq 'Test Page'
        expect(model.instance_variable_get('@slug')).to eq 'test-page'
      end

      it 'the default_env configuration endpoint can be over written' do
        expected_params[-1] = :preview
        expect(ContentfulRedis::Request).to receive(:new)
          .with(*expected_params)
          .and_return(instance_double(ContentfulRedis::Request, call: build(:request, :as_response)))

        model = ContentfulRedis::ModelBase.update(subject.id, :preview)
        expect(model).to be_a ContentfulRedis::ModelBase
        expect(model.id).to eq subject.id
      end
    end

    describe '#destroy(id)' do
      let(:content_model_key) { "xxxx/cdn/sys.id-#{subject.id}/content_type-#{subject.class.content_model}/include-1" }
      # Simulating id to be a searchable field
      let(:attribute_index_key) { "xxxx/#{subject.class.content_model}/#{subject.id}" }

      before do
        ContentfulRedis.redis.set(content_model_key, 1)
        ContentfulRedis.redis.set(attribute_index_key, 1)
        allow(subject.class).to receive(:searchable_fields).and_return(['id'])
        allow(ContentfulRedis::ModelBase).to receive(:find).and_return(subject)
      end

      it 'returns the number of redis keys deleted' do
        expect(ContentfulRedis::ModelBase.destroy(subject.id)).to eq 2
      end

      it 'deletes content_model_key (find key)' do
        expect(ContentfulRedis.redis.exists(content_model_key)).to be true

        ContentfulRedis::ModelBase.destroy(subject.id)

        expect(ContentfulRedis.redis.exists(content_model_key)).to be false
      end

      it 'deletes attribute_index keys (search keys)' do
        expect(ContentfulRedis.redis.exists(attribute_index_key)).to be true

        ContentfulRedis::ModelBase.destroy(subject.id)

        expect(ContentfulRedis.redis.exists(attribute_index_key)).to be false
      end
    end

    describe '#space' do
      it 'returns the default(first) configured space' do
        expect(ContentfulRedis::ModelBase.space).to eq(access_token: 'xxxx', preview_access_token: 'xxxx', space_id: 'xxxx')
      end
    end

    describe '#content_model' do
      it 'translates the ruby call name to a `Contentful model` name' do
        expect(subject.class.content_model).to eq 'modelBase'
      end
    end

    describe '#searchable_fields' do
      it 'defaults to an empty array' do
        expect(subject.class.searchable_fields).to eq []
      end

      context '#define_searchable_fields' do
        it 'overwrites the searchable_fields' do
          Model = Class.new(ContentfulRedis::ModelBase)
          Model.define_searchable_fields(:slug)

          expect(Model.searchable_fields).to eq [:slug]
        end
      end
    end
  end

  context 'instance methods' do
    describe '#content_type' do
      it 'converts the Contentful Model name into a ruby syntax content_type' do
        expect(subject.content_type).to eq 'model_base'
      end
    end

    describe '#destroy' do
      let(:content_model_key) { "xxxx/cdn/sys.id-#{subject.id}/content_type-#{subject.class.content_model}/include-1" }
      # Simulating id to be a searchable field
      let(:attribute_index_key) { "xxxx/#{subject.class.content_model}/#{subject.id}" }

      before do
        ContentfulRedis.redis.set(content_model_key, 1)
        ContentfulRedis.redis.set(attribute_index_key, 1)
        allow(subject.class).to receive(:searchable_fields).and_return(['id'])
      end

      it 'returns the number of redis keys deleted' do
        expect(subject.destroy).to eq 2
      end

      it 'deletes content_model_key (find key)' do
        expect(ContentfulRedis.redis.exists(content_model_key)).to be true

        subject.destroy

        expect(ContentfulRedis.redis.exists(content_model_key)).to be false
      end

      it 'deletes attribute_index keys (search keys)' do
        expect(ContentfulRedis.redis.exists(attribute_index_key)).to be true

        subject.destroy

        expect(ContentfulRedis.redis.exists(attribute_index_key)).to be false
      end
    end
  end

  describe '#endpoint' do
    context 'when environment for is published' do
      it 'return endpoint for the environment' do
        expect(subject.send(:endpoint)).to eq 'cdn'
      end
    end

    context 'when environment for is preview' do
      it 'return endpoint for the environment' do
        allow(subject.class).to receive(:request_env).and_return(:preview)

        expect(subject.send(:endpoint)).to eq 'preview'
      end
    end
  end

  context 'exceptions' do
    it 'raises a ArgumentError not finding by a searchable field' do
      expect do
        ContentfulRedis::ModelBase.find_by(error: '')
      end.to raise_error ContentfulRedis::Error::ArgumentError
    end

    it 'raises a ArgumentError when #find is called without a string id' do
      expect do
        ContentfulRedis::ModelBase.find(id: 'xxxx')
      end.to raise_error ContentfulRedis::Error::ArgumentError
    end
  end
end
