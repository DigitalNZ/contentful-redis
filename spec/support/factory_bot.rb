# frozen_string_literal: true

require 'factory_bot'
Dir["#{Dir.pwd}/spec/factories/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
