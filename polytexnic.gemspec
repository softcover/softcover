# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polytexnic/version'

Gem::Specification.new do |gem|
  gem.name          = "polytexnic"
  gem.version       = Polytexnic::VERSION
  gem.authors       = ["Nick Merwin", "Michael Hartl"]
  gem.email         = ["nick@lemurheavy.com"]
  gem.description   = %q{CLI interface for softcover.io}
  gem.summary       = %q{publish books}
  gem.homepage      = "http://softcover.io"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'polytexnic-core'
  gem.add_dependency 'msgpack', '~> 0.4.2'
  gem.add_dependency 'nokogiri', '~> 1.5.0'
  gem.add_dependency 'thor'
  gem.add_dependency 'activesupport'
  gem.add_dependency 'rest-client'
  gem.add_dependency 'curb'
  gem.add_dependency 'ruby-progressbar'
  gem.add_dependency 'maruku'
  gem.add_dependency 'pygments.rb'
  gem.add_dependency 'kramdown'

  gem.add_dependency 'sinatra'
  gem.add_dependency 'sinatra-respond_to'
  gem.add_dependency 'coffee-script'
  gem.add_dependency 'listen'
  gem.add_dependency 'rb-fsevent'
end
