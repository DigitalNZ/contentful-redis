RSpec.describe ContentfulRedis do
  it "has a version number" do
    expect(ContentfulRedis::VERSION).not_to be nil
  end

  describe 'configuration' do
    let(:space_config) do
      { 
        test_space: {
          id: 'xxxx',
          access_token: 'xxxx',
          preview_access_token: 'xxxx'
        }
      }
    end

    it 'can configure space information' do
      ContentfulRedis.configure do |config|
        config.spaces = space_config
      end
      
      expect(ContentfulRedis.configuration.spaces).to eq space_config
    end
  end
end
