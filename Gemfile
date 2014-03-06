source 'https://rubygems.org'

gemspec

group :test do
  gem 'rspec'
  gem 'debugger2' unless ENV['CI'] || RUBY_VERSION == '1.9.3'
  gem 'webmock',   require: false
  gem 'coveralls', require: false
  gem 'rack-test'
  gem 'ruby-prof'
end

group :development do
  gem 'rake'
end