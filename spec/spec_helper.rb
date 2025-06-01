# require 'coveralls'
# Coveralls::Output.silent = !ENV['CI']
# Coveralls.wear!

require 'rubygems'
require 'bundler/setup'
require 'rspec/its'
require 'webmock/rspec'
require 'webmock_helpers'
require 'ostruct'
require 'pry'

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

  RSpec::Expectations.configuration.on_potential_false_positives = :nothing

  config.raise_errors_for_deprecations!
end

TEST_API_KEY = 'asdfasdfasdfasdfasdf'

# Captures a stream.
# This is taken directly from Rails Active Support `capture`.
# The `capture` method is deprecated because it's not thread-safe, but
# we don't care about that and the deprecation warnings are annoying.
def capture(stream)
  stream = stream.to_s
  captured_stream = Tempfile.new(stream)
  stream_io = eval("$#{stream}")
  origin_stream = stream_io.dup
  stream_io.reopen(captured_stream)

  yield

  stream_io.rewind
  return captured_stream.read
ensure
  captured_stream.close
  captured_stream.unlink
  stream_io.reopen(origin_stream)
end
