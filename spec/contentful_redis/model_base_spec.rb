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

    it 'raises a ClassNotFound error when a unknown contentful class is referenced' do
      expect do
        subject.send(:content_model_class, 'unknownType')
      end.to raise_error ContentfulRedis::Error::ClassNotFound
    end
  end
end
