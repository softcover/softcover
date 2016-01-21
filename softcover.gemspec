# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'softcover/version'

Gem::Specification.new do |gem|
  gem.name          = "softcover"
  gem.version       = Softcover::VERSION
  gem.authors       = ["Michael Hartl", "Nick Merwin"]
  gem.email         = ["michael@softcover.io"]
  gem.description   = %q{Command-line interface for softcover.io}
  gem.summary       = %q{An ebook production system & sales and marketing platform for technical authors}
  gem.homepage      = "http://manual.softcover.io/book"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'polytexnic', '~> 1.1.13'
  gem.add_dependency 'msgpack', '~> 0.4.2'
  gem.add_dependency 'nokogiri', '~> 1.6.0'
  gem.add_dependency 'thor', '~> 0.18.1'
  gem.add_dependency 'activesupport', '>= 3.2.16'
  gem.add_dependency 'i18n', '>= 0.6.11'
  gem.add_dependency 'rest-client', '~> 1.6.7'
  gem.add_dependency 'curb', '~> 0.8.5'
  gem.add_dependency 'ruby-progressbar', '~> 1.4.2'
  gem.add_dependency 'maruku', '~> 0.7.1'
  gem.add_dependency 'pygments.rb', '~> 0.6.0'
  gem.add_dependency 'kramdown', '~> 1.3.2'

  gem.add_dependency 'sinatra', '~> 1.4.4'
  gem.add_dependency 'thin', '~> 1.6.1'
  gem.add_dependency 'async_sinatra', '~> 1.1.0'
  gem.add_dependency 'sinatra-respond_to', '~> 0.9.0'
  gem.add_dependency 'coffee-script', '~> 2.2.0'
  gem.add_dependency 'listen', '~> 1.3.1'
  gem.add_dependency 'rb-fsevent', '~> 0.9.3'
  gem.add_dependency 'sanitize', '~> 3.0.3'
end
