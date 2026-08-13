require "test_helper"

class BannerTest < ActionDispatch::IntegrationTest
  setup do
    Consently.reset!
    Consently.configure { |c| c.tag :google_analytics, id: "G-TEST" }
  end

  teardown { Consently.reset! }

  test "the card is shown until a choice is made" do
    get "/page"

    assert_select "#consently[data-controller='consently-banner']"
    assert_select "[data-consently-banner-target='card']" do |cards|
      assert_not_includes cards.sole["class"], "consently-hidden"
    end
    assert_select "button[data-action='consently-banner#acceptAll']"
    assert_select "button[data-action='consently-banner#rejectAll']"
  end

  test "after a choice the card is hidden but stays on the page, so it can be reopened" do
    cookies[Consently.config.cookie_name] = { v: 1, c: [ "analytics" ], t: Time.current.iso8601 }.to_json

    get "/page"

    assert_select "#consently"
    assert_select "[data-consently-banner-target='card']" do |cards|
      assert_includes cards.sole["class"], "consently-hidden"
    end
    assert_select "a[data-consently-open][href='#consently']"
  end

  test "the panel offers every optional category and remembers what was granted" do
    Consently.config.category :personalization
    cookies[Consently.config.cookie_name] = { v: 1, c: [ "marketing" ], t: Time.current.iso8601 }.to_json

    get "/page"

    assert_select "input[data-consently-banner-target='category'][value='analytics']:not([checked])"
    assert_select "input[data-consently-banner-target='category'][value='marketing'][checked]"
    assert_select "input[data-consently-banner-target='category'][value='personalization']"
  end

  test "the banner speaks the locale of the page" do
    get "/page?locale=pl"

    assert_match "Akceptuję wszystkie", response.body
  end

  test "the policy link is only rendered when there is one" do
    get "/page"
    assert_select "#consently a[href]", false

    Consently.config.policy_url = "/cookies"
    get "/page"
    assert_select "#consently a[href='/cookies']"
  end

  test "the page is left alone after a choice unless asked to reload" do
    get "/page"
    assert_select "#consently[data-consently-banner-reload-value='false']"

    Consently.config.reload_after_choice = true
    get "/page"
    assert_select "#consently[data-consently-banner-reload-value='true']"
  end

  test "a visitor who does not have to be asked gets the tags and no banner" do
    Consently.config.consent_required = ->(request) { request.host != "example.org" }

    get "http://example.org/page"
    assert_select "#consently", false
    assert_select "script[src*='G-TEST']"
    assert_select "script[type='text/plain']", false

    get "http://example.com/page"
    assert_select "#consently"
    assert_select "script[type='text/plain']"
  end

  test "the banner is announced and its panel is wired to the button that opens it" do
    get "/page"

    assert_select "[data-consently-banner-target='card'][role='dialog'][aria-labelledby='consently-message']"
    assert_select "#consently-message"
    assert_select "[data-consently-banner-target='settingsButton'][aria-expanded='false'][aria-controls='consently-preferences']"
    assert_select "#consently-preferences"
  end

  test "the cookie domain is passed on, so a consent can cover subdomains" do
    get "/page"
    assert_select "#consently[data-consently-banner-domain-value='']"

    Consently.config.cookie_domain = ".example.com"
    get "/page"
    assert_select "#consently[data-consently-banner-domain-value='.example.com']"
  end

  test "the log url is left empty unless consent logging is on" do
    get "/page"
    assert_select "#consently[data-consently-banner-log-url-value='']"

    Consently.config.log_consents = true
    get "/page"
    assert_select "#consently[data-consently-banner-log-url-value='/consently/consents']"
  end
end
