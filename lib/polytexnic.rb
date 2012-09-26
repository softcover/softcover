require 'active_support/core_ext/string'

require 'polytexnic/formats'
Dir[File.dirname(__FILE__) + '/polytexnic/**/*.rb'].each{|f| require f}

module Polytexnic
end
