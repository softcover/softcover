# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'softcover/version'

Gem::Specification.new do |gem|
  gem.name          = "softcover"
  gem.version       = Softcover::VERSION
  gem.authors       = ["Michael Hartl", "Nick Merwin"]
  gem.email         = ["michael@softcover.io"]
  gem.description   = %q{CLI interface for softcover.io}
  gem.summary       = %q{A typesetting system for technical authors}
  gem.homepage      = "http://manual.softcover.io/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'polytexnic', '~> 0.7.0'
  gem.add_dependency 'msgpack', '~> 0.4.2'
  gem.add_dependency 'nokogiri', '~> 1.6.0'
  gem.add_dependency 'thor'
  gem.add_dependency 'activesupport'
  gem.add_dependency 'rest-client'
  gem.add_dependency 'curb'
  gem.add_dependency 'ruby-progressbar'
  gem.add_dependency 'maruku'
  gem.add_dependency 'pygments.rb'
  gem.add_dependency 'kramdown'

  gem.add_dependency 'sinatra'
  gem.add_dependency 'thin'
  gem.add_dependency 'async_sinatra'
  gem.add_dependency 'sinatra-respond_to'
  gem.add_dependency 'coffee-script'
  gem.add_dependency 'listen', '~> 1.3.1'
  gem.add_dependency 'rb-fsevent', '~> 0.9.3'
  gem.add_dependency 'sanitize'
end
