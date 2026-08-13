require "application_system_test_case"

# The blocking is only worth anything if it holds up in a real browser: these
# drive the banner the way a visitor would and then look at what the page is
# actually running.
class ConsentTest < ApplicationSystemTestCase
  BLOCKED = 'script[type="text/plain"][data-consently-category]'.freeze
  ANALYTICS = 'script[src*="googletagmanager"]'.freeze
  MARKETING = "script[data-consently-category='marketing']:not([type='text/plain'])".freeze

  setup do
    Consently.configure do |c|
      c.tag :google_analytics, id: "G-SYSTEM"
      c.tag :meta_pixel, id: "1234567890"
    end
  end

  test "the tags sit blocked until someone accepts, then run without a reload" do
    visit "/page"

    assert_equal 3, script_count(BLOCKED)
    assert_equal 0, script_count(ANALYTICS)

    click_on "Accept all"

    assert_equal 0, script_count(BLOCKED)
    assert_equal 1, script_count(ANALYTICS)
    assert_equal %w[analytics marketing], consently_cookie_value["c"]
  end

  test "rejecting leaves everything blocked and still records the choice" do
    visit "/page"

    click_on "Reject all"

    assert_equal 3, script_count(BLOCKED)
    assert_equal 0, script_count(ANALYTICS)
    assert_empty consently_cookie_value["c"]
  end

  test "the panel releases exactly what was ticked" do
    visit "/page"

    click_on "Settings"
    check "consently-analytics"
    click_on "Save choices"

    assert_equal 1, script_count(ANALYTICS)
    assert_equal 0, script_count(MARKETING)
    assert_equal %w[analytics], consently_cookie_value["c"]
  end

  test "the panel can be left without deciding anything" do
    visit "/page"

    click_on "Settings"
    assert_selector "label", text: "Analytics"

    click_on "Cancel"

    assert_no_selector "label", text: "Analytics"
    assert_selector "button", text: "Accept all"
    assert_nil consently_cookie_value
  end

  test "a visitor who has already chosen is not asked again, but can reopen the panel" do
    visit "/page"
    click_on "Accept all"

    visit "/page"
    assert_no_selector "button", text: "Accept all"

    click_on "Cookie settings"
    assert_selector "button", text: "Save choices"
    # The panel comes back showing what was agreed to last time.
    assert_checked_field "consently-analytics"
  end

  test "a blocked embed becomes an iframe the moment its category is granted" do
    visit "/embeds"

    assert_no_selector "iframe", visible: :all
    assert_selector "button", text: "Allow and show"

    click_on "Accept all"

    # Marketing and analytics both granted, so every embed on the page appears.
    assert_selector "iframe.consently-embed__frame", count: 4, visible: :all
    assert_no_selector "button", text: "Allow and show"
  end

  test "an embed whose category was refused stays a placeholder" do
    visit "/embeds"

    click_on "Settings"
    check "consently-analytics"
    click_on "Save choices"

    # The analytics one is the Vimeo embed; the marketing ones keep waiting.
    assert_selector "iframe[src*='vimeo']", count: 1, visible: :all
    assert_no_selector "iframe[src*='youtube']", visible: :all
  end

  test "the tags are blocked again once the policy version moves on" do
    visit "/page"
    click_on "Accept all"
    assert_equal 1, script_count(ANALYTICS)

    Consently.config.consent_version = 2
    visit "/page"

    assert_equal 3, script_count(BLOCKED)
    assert_selector "button", text: "Accept all"
  end
end
