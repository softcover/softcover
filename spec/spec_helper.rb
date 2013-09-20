require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'

require 'webmock_helpers'

require 'simplecov'
SimpleCov.start

require 'json'
require 'polytexnic'
require 'polytexnic/utils'
require 'polytexnic/config'
require 'polytexnic/server/app'
require 'polytexnic/commands/publisher'
Polytexnic::Output.silence!

# Load support files.
Dir.glob(File.join(File.dirname(__FILE__), "./support/**/*.rb")).each do |f|
  require_relative(f)
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Polytexnic::set_test_mode!

  config.before do
    Polytexnic::set_test_mode!
    Polytexnic::Utils.reset_current_book!
    Polytexnic::Config.remove
    Polytexnic::BookConfig.remove
  end

  config.before(:each) do
    Polytexnic::Output.silence!
    Polytexnic::Commands::Server.no_listener = true
  end

  config.after do
    Polytexnic::Config.remove
    Polytexnic::BookConfig.remove
  end

  config.include WebmockHelpers
end

TEST_API_KEY = 'asdfasdfasdfasdfasdf'

def silence
  return yield if ENV['silence'] == 'false'

  silence_stream(STDOUT) do
    yield
  end
end
