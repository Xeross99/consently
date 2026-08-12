source "https://rubygems.org"

# Specify your gem's dependencies in consently.gemspec.
gemspec

# CI runs the suite against several Rails versions; locally you get whatever
# is current.
gem "rails", ENV["RAILS_VERSION"] if ENV["RAILS_VERSION"]

gem "puma"
gem "sqlite3"
gem "propshaft"

# The banner is a Stimulus controller pinned by the engine, so the dummy
# application needs the real setup rather than a stand-in.
gem "importmap-rails"
gem "stimulus-rails"

# System tests: the blocking only matters if it is exercised in a browser.
gem "capybara"
gem "selenium-webdriver"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false
