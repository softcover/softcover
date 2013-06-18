require 'polytexnic-core'
require 'active_support/core_ext/string'

require_relative 'polytexnic/formats'
require_relative 'polytexnic/utils'

Dir[File.join(File.dirname(__FILE__), '/polytexnic/**/*.rb')].each do |file|
  require file.chomp(File.extname(file))
end

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
