require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'
require 'webmock_helpers'
require 'ostruct'

require 'json'
require 'softcover'
require 'softcover/utils'
require 'softcover/config'
require 'softcover/server/app'
require 'softcover/commands/publisher'
Softcover::Output.silence!

# Load support files.
Dir.glob(File.join(File.dirname(__FILE__), "./support/**/*.rb")).each do |f|
  require_relative(f)
end

RSpec.configure do |config|
  include Softcover::Utils
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Softcover::set_test_mode!

  config.before do
    Softcover::set_test_mode!
    Softcover::Utils.reset_current_book!
    Softcover::Config.remove
    Softcover::BookConfig.remove
  end

  config.before(:each) do
    Softcover::Output.silence!
    Softcover::Commands::Server.no_listener = true
  end

  config.after do
    Softcover::Config.remove
    Softcover::BookConfig.remove
  end

  config.include WebmockHelpers
end

TEST_API_KEY = 'asdfasdfasdfasdfasdf'

