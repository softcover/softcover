# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polytexnic/version'

Gem::Specification.new do |gem|
  gem.name          = "polytexnic"
  gem.version       = Polytexnic::VERSION
  gem.authors       = ["Nick Merwin"]
  gem.email         = ["nick@lemurheavy.com"]
  gem.description   = %q{CLI interface for polytexnic.com}
  gem.summary       = %q{publish books}
  gem.homepage      = "http://polytexnic.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
