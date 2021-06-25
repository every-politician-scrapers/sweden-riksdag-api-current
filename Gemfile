# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 2.6.0'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'daff'
gem 'open-uri-cached'
gem 'pry'
gem 'rake'
gem 'scraped', github: 'everypolitician/scraped', branch: 'scraper-class'

group :test do
  gem 'reek', '~> 6.0'
  gem 'rubocop', '~> 0.89'
end
