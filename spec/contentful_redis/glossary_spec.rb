# frozen_string_literal: true

require 'spec_helper'
require 'support/setup'

RSpec.describe ContentfulRedis::Glossary, vrc: true, contentful: true do
  let!(:test_class) { Page = Class.new(ContentfulRedis::ModelBase) }
  subject { ContentfulRedis::Glossary.new(Page, :slug) }

  context 'initialize' do
    it 'references a klass' do
      expect(subject.instance_variable_get(:@klass)).to eq Page
    end

    it 'has an attribute' do
      expect(subject.instance_variable_get(:@attribute)).to eq 'slug'
    end
  end

  it 'constructs a mapping between a content models attribute and the content models id' do
    keys = subject.call

    expect(keys).to all(match(%r{.+/page/.+}))
    keys.each do |key|
      expect($redis.get(key)).to be_present
    end
  end
end
