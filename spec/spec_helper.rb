require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'
require 'spork'
require 'spork/ext/ruby-debug'

require 'simplecov'
SimpleCov.start

require 'polytexnic'

require 'webmock_helpers'

Spork.prefork do
  RSpec.configure do |config|
    config.before do
      Polytexnic::set_test_mode!
      Polytexnic::Config.remove
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
end

# Spork.each_run do
#   require 'simplecov'
#   SimpleCov.start
# end
