# frozen_string_literal: true

require 'spec_helper'
require 'support/setup.rb'

RSpec.describe ContentfulRedis::Asset, contentful: true do
  subject { build(:contentful_asset) }

  it 'has an id' do
    expect(subject.id).to eq 'XXXX'
  end

  it 'has a title' do
    expect(subject.title).to eq 'Asset Title'
  end

  it 'has a description' do
    expect(subject.description).to eq 'Asset description'
  end

  it 'has a url' do
    expect(subject.url).to eq '//images.ctfassets.net/space/XXXX/XXXX/image.jpg'
  end

  it 'has details' do
    expect(subject.details).to eq('size' => 73_037, 'image' => { 'width' => 1080, 'height' => 1519 })
  end

  it 'has a file_name' do
    expect(subject.file_name).to eq 'image.jpg'
  end

  it 'has a content_type' do
    expect(subject.content_type).to eq 'image/jpeg'
  end
end
