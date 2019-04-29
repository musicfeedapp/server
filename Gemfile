source 'https://rubygems.org'

ruby '2.3.3'

gem 'rack', '~> 1.6.0'
gem 'rails', '4.2.8'
gem 'uglifier'
gem 'sendgrid'

gem 'sitemap_generator'

gem 'sass'

gem 'jquery-rails'

gem 'gentelella-rails', github: 'oivoodoo/gentelella-rails'
gem 'modernizr-rails'
gem 'coffee-rails'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'sass-rails', '>= 3.2'

# gem 'airbrake', '~> 5.1'

gem 'aggregator', path: './gems/aggregator'
gem 'google-api-client', '0.8.6'

gem "rack-cache"

gem 'pg'
gem 'pg_array_parser'
gem 'postgres_ext'

gem 'acts_as_commentable'

gem 'simple-conf'

# Api endpoints
gem 'grape'
gem 'grape-rabl'

# Nullable pattern, say bye to nil
gem 'naught'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

gem 'minitest'
gem 'multi_json'
gem 'json'

gem 'devise', github: 'plataformatec/devise'

gem 'unf'
gem 'oj'

gem 'choices'
gem 'redis'
gem 'redis-namespace'

gem 'kaminari', github: 'amatsuda/kaminari'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'awesome_print'

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'capistrano3-puma'
end

group :development, :test do
  gem 'annotate', ">=2.6.0"

  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'benchmark-ips'
end

group :production do
  gem 'puma'
end

group :test do
  gem 'rack-test'

  gem 'timecop'
  gem 'mock_redis'

  %w[rspec-core rspec-expectations rspec-support rspec-collection_matchers].each do |lib|
    gem lib, github: "rspec/#{lib}", branch: 'master'
  end
  gem 'rspec-mocks', github: 'rspec/rspec-mocks'
  gem 'rspec-rails', github: 'rspec/rspec-rails'

  gem 'rails-controller-testing'

  gem 'shoulda-matchers'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-twitter'

gem 'faraday', require: false
gem 'retryable', github: 'nfedyashev/retryable'

gem 'koala'
gem 'rspotify'
gem 'yourub'
gem 'lastfm'
gem "parse-ruby-client"

gem 'encrypted_strings'

# background processing worker
gem 'sidekiq'
gem 'sidekiq-unique-jobs', '4.0.13'
gem 'sidekiq_mailer'

gem "bunny"

gem 'sinatra'

gem 'elasticsearch-model'
gem 'elasticsearch-rails'

gem 'le'

gem "statsd-instrument"

# upload images
gem 'carrierwave'
gem 'mini_magick'

# store image at s3
gem "fog"

gem 'twitter'
