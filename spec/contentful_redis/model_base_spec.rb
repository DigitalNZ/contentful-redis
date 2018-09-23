# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::ModelBase, contentful: true do
  subject { build(:contentful_model_base) }

  context 'class level methods' do
    it 'defines a default space' do
      expect(ContentfulRedis::ModelBase.space).to be_a(Hash)
      expect(ContentfulRedis::ModelBase.space.keys).to eq [:space_id, :access_token, :preview_access_token]
    end

    it 'class name to Contentful content_model name' do
      expect(ContentfulRedis::ModelBase.content_model).to eq 'modelBase'
    end

    it 'defines the find method' do
      expect(ContentfulRedis::ModelBase).to respond_to(:find)
    end

    it 'defines the find_by method' do
      expect(ContentfulRedis::ModelBase).to respond_to(:find_by)
    end

    context '#request_env' do
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

    context '#find' do
      it 'can query by id'
      it 'the default_env configuration endpoint can be over written'
    end

    context '#find_by' do
      it 'can query by searchable attribute'
      it 'the default_env configuration endpoint can be over written'
      it 'throws an error when the query attribute is not a searchable attribute'
    end

    context '#update' do
      it 'can trigger a redis update'
      it 'the default_env configuration endpoint can be over written'
    end

    context '#delete' do
      it 'can trigger a redis delete'
      it 'the default_env configuration endpoint can be over written'
    end

    context '#space' do
      it 'returns the default / first configured space'
    end

    context '#content_model' do
      it 'translates the ruby call name to a `Contentful model` name' do
        expect(subject.class.content_model).to eq 'modelBase'
      end
    end

    context '#searchable_fields' do
      it 'defaults to an empty array' do
        expect(subject.class.searchable_fields).to eq []
      end

      context '#define_searchable_fields' do
        it 'overwrites the searchable_fields' do
          subject.class.define_searchable_fields(:slug)
          expect(subject.class.searchable_fields).to eq [:slug]
        end
      end
    end
  end

  context 'instance methods' do
    it 'defines the initializer for ContentfulRedis intergration' do
      expect(subject).to be_a(ContentfulRedis::ModelBase)
    end

    it 'has a ruby syntax content_type' do
      expect(subject.content_type).to eq 'model_base'
    end
  end

  context 'exceptions' do
    it 'raises a ArgumentError not finding by slud :(' do
      expect do
        ContentfulRedis::ModelBase.find_by(error: '')
      end.to raise_error ContentfulRedis::Error::ArgumentError
    end

    it 'raises a RecordNotFound error when the attribute does not have reference in the glossary' do
      expect do
        ContentfulRedis::ModelBase.find_by(slug: 'not-a-record')
      end.to raise_error ContentfulRedis::Error::RecordNotFound
    end
  end
end
