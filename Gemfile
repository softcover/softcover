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
  gem 'rspec', '3.13.0'
  gem 'rspec-its', '~> 2.0'
  gem 'safe_yaml', '1.0.4'
  gem 'webmock', '~> 3',  require: false
  # gem 'coveralls', require: false
  gem 'rack-test'
  gem 'ruby-prof'
  gem 'pry'
end

group :development do
  gem 'rake'
end