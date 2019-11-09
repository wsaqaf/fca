source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.6', '>= 5.1.6.1'
gem 'pg'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'simple_form', '~> 5.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'devise', '~> 4.5'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'turbolinks', '~> 2.1'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'rails-jquery-autocomplete'
gem 'autocomplete_rails'
gem 'rb-readline'
gem 'hirb'
gem 'link_thumbnailer'
gem 'wicked'
gem 'pagy'
gem 'onebox'
gem 'jquery-turbolinks'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'popper_js', '~> 1.11.1'

source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
  # add the line below
  gem 'rails-assets-chosen'
end

group :development do
  gem "capistrano", "~> 3.11", require: false
end
