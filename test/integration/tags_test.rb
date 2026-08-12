require "test_helper"

# What a host application's page actually contains, which is the only place
# the blocking either works or does not.
class TagsTest < ActionDispatch::IntegrationTest
  setup do
    Consently.reset!
    Consently.configure do |c|
      c.tag :google_analytics, id: "G-TEST"
      c.tag :meta_pixel, id: "1234567890"
      c.tag :plausible, domain: "example.com", category: :necessary
    end
  end

  teardown { Consently.reset! }

  test "without consent every optional tag is inert" do
    get "/page"

    assert_select "script[type='text/plain'][data-consently-category='analytics'][data-consently-src*='G-TEST']"
    assert_select "script[type='text/plain'][data-consently-category='marketing']"
    # The src lives in a data attribute, so the browser does not even fetch it.
    assert_no_match(/ src=["']https:\/\/www\.googletagmanager\.com/, response.body)
  end

  test "a tag put in the necessary category runs before anyone clicks" do
    get "/page"

    assert_select "script[data-consently-category='necessary'][src*='plausible'][data-domain='example.com']"
  end

  test "consent releases exactly the categories it covers" do
    consent_to "analytics"

    get "/page"

    assert_select "script[src*='G-TEST'][data-consently-category='analytics']"
    assert_select "script[type='text/plain'][data-consently-category='analytics']", false
    assert_select "script[type='text/plain'][data-consently-category='marketing']"
  end

  test "consent from an older policy version counts for nothing" do
    consent_to "analytics", version: 99

    get "/page"

    assert_select "script[type='text/plain'][data-consently-category='analytics']"
  end

  test "google consent mode denies everything up front and updates on consent" do
    get "/page"

    assert_match "gtag('consent', 'default'", response.body
    assert_no_match(/gtag\('consent', 'update'/, response.body)

    consent_to "analytics"
    get "/page"

    assert_match "'analytics_storage': 'granted'", response.body
    assert_match "'ad_storage': 'denied'", response.body
  end

  test "consent mode can be switched off" do
    Consently.config.google_consent_mode = false

    get "/page"

    assert_no_match(/gtag\('consent'/, response.body)
  end

  test "noscript fallbacks only appear for granted categories" do
    Consently.configure { |c| c.tag :google_tag_manager, id: "GTM-TEST" }

    get "/page"
    assert_select "noscript", false

    consent_to "analytics"
    get "/page"
    assert_select "noscript iframe[src*='GTM-TEST']"
  end

  test "the banner brings its own stylesheet, and can be told not to" do
    get "/page"
    assert_select "link[rel='stylesheet'][href*='consently']"

    Consently.config.stylesheet = false
    get "/page"
    assert_select "link[rel='stylesheet'][href*='consently']", false
  end

  test "nothing is rendered where Consently is turned off" do
    Consently.config.enabled = false

    get "/page"

    assert_no_match(/G-TEST/, response.body)
    assert_select "#consently", false
  end

  test "the scope resolver picks the tags for the host" do
    Consently.reset!
    Consently.configure do |c|
      c.scope_resolver = ->(request) { request.host }
      c.tag :google_analytics, id: "G-DEFAULT"
      c.scope("example.org") { |s| s.tag :google_analytics, id: "G-SCOPED" }
    end

    get "http://example.org/page"
    assert_match "G-SCOPED", response.body

    get "http://example.com/page"
    assert_match "G-DEFAULT", response.body
  end

  private

  def consent_to(*categories, version: Consently.config.consent_version)
    cookies[Consently.config.cookie_name] =
      { v: version, c: categories, t: Time.current.iso8601 }.to_json
  end
end
