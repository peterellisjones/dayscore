source 'https://rubygems.org'
ruby '1.9.3'

gem 'rails', '3.2.8'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'compass-rails'
  gem 'twitter-bootstrap-rails'
  gem 'uglifier'
end

gem 'jquery-rails'
gem 'less-rails'

group :development do
  gem "haml-rails"
  gem "hpricot"
  gem "ruby_parser"
  gem 'quiet_assets'
end

group :production do
  gem 'unicorn'
  gem "yui-compressor"
end

gem "mongoid", ">= 3.0.5"
gem "bson_ext"
gem "haml", ">= 3.1.7"
gem "rspec-rails", ">= 2.11.0", :group => [:development, :test]
gem "capybara", ">= 1.1.2", :group => :test
gem "database_cleaner", ">= 0.8.0", :group => :test
gem "mongoid-rspec", ">= 1.4.6", :group => :test
gem "email_spec", ">= 1.2.1", :group => :test
gem "cucumber-rails", ">= 1.3.0", :group => :test, :require => false
gem "launchy", ">= 2.1.2", :group => :test
gem "factory_girl_rails", ">= 4.0.0", :group => [:development, :test]
gem "therubyracer", ">= 0.10.2", :group => :assets, :platform => :ruby
gem "simple_form", ">= 2.0.2"
gem 'newrelic_rpm'