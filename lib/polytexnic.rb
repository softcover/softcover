t = Time.now

$stderr.puts "foo"
require 'polytexnic-core'
require 'active_support/core_ext/string'

require_relative 'polytexnic/formats'
require_relative 'polytexnic/utils'

$stderr.puts Time.now - t
$stderr.puts "bar"

# Dir[File.join(File.dirname(__FILE__), '/polytexnic/**/*.rb')].each do |file|
#   t1 = Time.now
#   require file.chomp(File.extname(file))
#   $stderr.puts "#{Time.now - t1} #{File.basename(file)}"
# end

require_relative 'polytexnic/book'
require_relative 'polytexnic/book_manifest'
require_relative 'polytexnic/builder'
require_relative 'polytexnic/builders/epub'
require_relative 'polytexnic/builders/html'
require_relative 'polytexnic/builders/mobi'
require_relative 'polytexnic/builders/pdf'
require_relative 'polytexnic/cli'
require_relative 'polytexnic/commands/auth'
require_relative 'polytexnic/commands/build'
require_relative 'polytexnic/commands/epub_validator'
require_relative 'polytexnic/commands/generator'
require_relative 'polytexnic/commands/opener'
require_relative 'polytexnic/commands/publisher'
require_relative 'polytexnic/commands/server'
require_relative 'polytexnic/uploader'
require_relative 'polytexnic/version'

$stderr.puts "baz"

module Polytexnic
  extend self

  include Polytexnic::Utils

  def set_test_mode!
    @test_mode = true
  end

  def test?
    @test_mode
  end
end
