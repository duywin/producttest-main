source "https://rubygems.org"

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "7.1.4"
gem 'railties', "7.1.4"
gem 'highcharts-rails' , "6.0.0"
gem "haml-rails"
gem 'html2haml'
gem 'coffee-script'
gem 'mini_racer'



# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"


# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
gem 'jquery-rails', '4.6'
gem 'ransack'
gem 'kaminari'
gem 'elasticsearch', '~> 8.0'
gem 'elasticsearch-model', '~> 7.0'
gem 'elasticsearch-rails', '~> 7.0'



gem 'devise', '~> 4.9', '>= 4.9.3'
gem 'bcrypt', '3.1.20'
gem 'devise-otp'
gem 'rotp', '6.3.0'


gem 'rack', '2.2.4'
gem 'minitest', '5.25.1'
gem 'sinatra', '3.2.0'


# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem 'font-awesome-rails'
gem 'carmen'
gem 'activerecord-import', '~> 1.4'
gem 'roo'
gem 'caxlsx', '~> 3.2'
gem 'caxlsx_rails', '~> 0.6.3'  # This is optional if you plan to render Excel files in Rails views
gem 'whenever', :require => false


group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem 'rspec-rails'


end

group :development do
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
