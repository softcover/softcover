require 'active_support/core_ext/string'

require 'polytexnic/formats'
Dir[File.dirname(__FILE__) + '/polytexnic/**/*.rb'].each{|f| require f}

module Polytexnic
	extend self

	def set_test_mode!
		@test_mode = true
	end

	def test?
		@test_mode
	end
end
