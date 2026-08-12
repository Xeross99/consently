source "https://rubygems.org"

# Specify your gem's dependencies in consently.gemspec.
gemspec

# CI runs the suite against several Rails versions; locally you get whatever
# is current.
gem "rails", ENV["RAILS_VERSION"] unless ENV["RAILS_VERSION"].to_s.empty?

# Rails 7.1's test runner calls Minitest with an argument list Minitest 6 no
# longer accepts, so that combination pins the older one.
gem "minitest", ENV["MINITEST_VERSION"] unless ENV["MINITEST_VERSION"].to_s.empty?

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
