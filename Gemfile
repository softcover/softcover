source 'http://rubygems.org'

ruby "1.9.3"

gem 'rails', '3.2.8'
gem 'pg'

gem 'devise'

gem 'jquery-rails'
gem 'haml-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets, :production do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem "guard", ">= 1.3.0"
  gem 'guard-spork'
  gem "guard-rspec"
end

group :development, :test do
  gem 'debugger'
  gem 'rails3-generators' # to generate factory_girl for testing
  gem "factory_girl_rails", ">= 4.0.0"
end

group :test do
  gem 'rspec-rails'
  gem "spork-rails"
end
