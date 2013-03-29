require 'polytexnic-core'
require 'active_support/core_ext/string'

require File.dirname(__FILE__) + '/polytexnic/formats'
require File.dirname(__FILE__) + '/polytexnic/utils'

Dir[File.dirname(__FILE__) + '/polytexnic/**/*.rb'].each{|f| require f}

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
