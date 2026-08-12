require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  setup { Consently.reset! }
  teardown { Consently.reset! }

  private

  # The cookie as the banner would have written it, for the cases that start
  # from a visitor who has already chosen.
  def consent_cookie(*categories, version: Consently.config.consent_version)
    { v: version.to_s, c: categories.map(&:to_s), t: Time.current.iso8601 }.to_json
  end

  def consently_cookie_value
    cookie = page.driver.browser.manage.cookie_named(Consently.config.cookie_name)
    JSON.parse(CGI.unescape(cookie[:value]))
  rescue Selenium::WebDriver::Error::NoSuchCookieError
    nil
  end

  # Scripts live in <head> and are never "visible" to Capybara.
  def script_count(selector)
    page.all(selector, visible: :all).size
  end
end
