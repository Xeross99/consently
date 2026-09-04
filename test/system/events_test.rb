require "application_system_test_case"

# Events are only worth anything if they reach the dataLayer in a real
# browser - and only after the click, not before.
class EventsTest < ApplicationSystemTestCase
  setup do
    Consently.configure { |c| c.tag :google_analytics, id: "G-SYSTEM" }
  end

  test "an event rendered before consent is sent the moment analytics is granted" do
    visit "/checkout"

    assert_equal [], sent_events

    click_on "Accept all"

    assert_event "purchase" do |params|
      assert_equal "1234", params["transaction_id"]
      assert_equal "TB-001", params["items"].first["item_id"]
    end
  end

  test "an event from a Turbo Stream waits for consent and is sent when it arrives" do
    visit "/cart"

    click_on "Add to cart"
    assert_no_event "add_to_cart"

    click_on "Accept all"

    assert_event "add_to_cart" do |params|
      assert_equal "EUR", params["currency"]
      assert_equal "Curved track", params["items"].first["item_name"]
    end
  end

  test "a Turbo Stream event goes straight out once consent exists" do
    visit "/cart"
    click_on "Accept all"

    click_on "Add to cart"

    assert_event "add_to_cart"
  end

  test "window.Consently.track queues until its category is granted" do
    visit "/page"

    page.execute_script("Consently.track('newsletter_signup', { source: 'test' })")
    assert_no_event "newsletter_signup"

    click_on "Settings"
    check "consently-analytics"
    click_on "Save choices"

    assert_event "newsletter_signup" do |params|
      assert_equal "test", params["source"]
    end
  end

  test "an event whose category was refused keeps waiting" do
    visit "/page"

    page.execute_script("Consently.track('lead', { value: 1 }, { category: 'marketing' })")

    click_on "Settings"
    check "consently-analytics"
    click_on "Save choices"

    assert_no_event "lead"
  end

  private

  # gtag() pushes its arguments object onto the dataLayer; read the event
  # calls back by position, the way gtag.js does.
  def sent_events
    page.evaluate_script(<<~JS)
      (window.dataLayer || []).filter((entry) => entry[0] === "event").map((entry) => [entry[1], entry[2]])
    JS
  end

  def assert_event(name)
    params = nil
    wait_until { params = sent_events.find { |event_name, _| event_name == name }&.last }

    assert params, "expected a #{name} event on the dataLayer, got #{sent_events.inspect}"
    yield params if block_given?
  end

  def assert_no_event(name)
    # Nothing to wait for on the way to "still not there", so give the page a
    # moment to be wrong first.
    sleep 0.3

    assert_nil sent_events.find { |event_name, _| event_name == name }, "did not expect a #{name} event yet"
  end

  def wait_until
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until yield
    end
  rescue Timeout::Error
    nil
  end
end
