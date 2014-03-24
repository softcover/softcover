source 'https://rubygems.org'

# Include a bunch of language encoding settings.
LANG="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

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