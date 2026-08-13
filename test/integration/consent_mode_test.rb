require "test_helper"

# Basic against advanced consent mode: the difference is whether Google's own
# tags are allowed on the page before anyone has agreed to anything.
class ConsentModeTest < ActionDispatch::IntegrationTest
  setup do
    Consently.reset!
    Consently.configure do |c|
      c.tag :google_analytics, id: "G-TEST"
      c.tag :clarity, id: "abcd1234"
    end
  end

  teardown { Consently.reset! }

  test "basic mode keeps every optional tag blocked, Google's included" do
    get "/page"

    assert_select "script[type='text/plain'][data-consently-src*='G-TEST']"
    assert_select "script[type='text/plain'][data-consently-category='analytics']", 3
    assert_match "gtag('consent', 'default'", response.body
  end

  test "advanced mode lets Google's tags load denied, and holds the rest back" do
    Consently.config.google_consent_mode = :advanced

    get "/page"

    # Google's tag runs and obeys the denied defaults it was just given.
    assert_select "script[src*='G-TEST'][data-consently-category='analytics']"
    assert_match "'analytics_storage': 'denied'", response.body
    # Everyone else still waits.
    assert_select "script[type='text/plain'][data-consently-category='analytics']"
    assert_no_match(/ src=["']https:\/\/www\.clarity\.ms/, response.body)
  end

  test "advanced mode changes nothing once consent is given" do
    Consently.config.google_consent_mode = :advanced
    cookies[Consently.config.cookie_name] =
      { v: 1, c: [ "analytics" ], t: Time.current.iso8601 }.to_json

    get "/page"

    assert_select "script[type='text/plain']", false
    assert_match "'analytics_storage': 'granted'", response.body
  end

  test "the mode is validated where it is set, not where it is read" do
    assert_raises(ArgumentError) { Consently.config.google_consent_mode = :whatever }

    Consently.config.google_consent_mode = true
    assert_equal :basic, Consently.config.google_consent_mode

    Consently.config.google_consent_mode = false
    get "/page"
    assert_no_match(/gtag\('consent'/, response.body)
  end
end
