require "test_helper"

# Events from views and from Turbo Stream responses, in the shape the page's
# tags read - and held back rather than dropped when consent is missing.
class EcommerceTest < ActionDispatch::IntegrationTest
  setup do
    Consently.reset!
    Consently.configure { |c| c.tag :google_analytics, id: "G-TEST" }
  end

  teardown { Consently.reset! }

  test "without consent the event is held back as an inert script, not dropped" do
    get "/checkout"

    assert_select "script[type='text/plain'][data-consently-category='analytics']", text: /purchase/
    assert_select "script:not([type='text/plain'])", text: /purchase/, count: 0
  end

  test "with consent the event is live" do
    consent_to "analytics"

    get "/checkout"

    assert_select "script:not([type='text/plain'])", text: /gtag\('event', "purchase"/
  end

  test "a page running gtag.js gets gtag('event') calls, with the items GA4 reads" do
    consent_to "analytics"

    get "/checkout"

    assert_match "gtag('event', \"purchase\"", response.body
    assert_match "\"transaction_id\":\"1234\"", response.body
    assert_match "\"item_id\":\"TB-001\"", response.body
    assert_match "\"item_name\":\"Straight track\"", response.body
    assert_match "\"quantity\":2", response.body
    assert_match "\"item_category\":\"Track\"", response.body
    assert_no_match(/ecommerce: null/, response.body)
  end

  test "a page running Google Tag Manager gets dataLayer pushes, cleared first as Google asks" do
    Consently.config.tag :google_tag_manager, id: "GTM-TEST"
    consent_to "analytics"

    get "/checkout"

    assert_match "window.dataLayer.push({ ecommerce: null });", response.body
    assert_match "\"event\":\"purchase\",\"ecommerce\":{", response.body
    assert_no_match(/gtag\('event'/, response.body)
  end

  test "the transport can be forced" do
    Consently.config.event_transport = :data_layer
    consent_to "analytics"

    get "/checkout"

    assert_match "\"event\":\"purchase\",\"ecommerce\":{", response.body
  end

  test "a plain hash is passed through untouched" do
    consent_to "analytics"

    get "/checkout?hash=1"

    assert_match "\"item_id\":\"RAW-1\"", response.body
  end

  test "the page tells the JavaScript side what is granted and how to send" do
    get "/checkout"
    assert_select "meta[name='consently-granted'][content='necessary']"
    assert_select "meta[name='consently-transport'][content='gtag']"

    consent_to "analytics"
    get "/checkout"
    assert_select "meta[name='consently-granted'][content='necessary analytics']"
  end

  test "a Turbo Stream response carries the event as a stream action, whatever the consent" do
    post "/cart", headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_select "turbo-stream[action='consently_event'][event='add_to_cart'][category='analytics'][ecommerce='true']" do |streams|
      payload = JSON.parse(streams.first["payload"])

      assert_equal "EUR", payload["currency"]
      assert_equal "TB-002", payload["items"].first["item_id"]
    end
    assert_no_match(/<script/, response.body)
  end

  test "nothing is rendered when the gem is switched off" do
    Consently.config.enabled = false
    consent_to "analytics"

    get "/checkout"
    assert_no_match(/purchase/, response.body)

    post "/cart", headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_no_match(/turbo-stream/, response.body)
  end

  private

  def consent_to(*categories)
    cookies[Consently.config.cookie_name] =
      { v: Consently.config.consent_version, c: categories, t: Time.current.iso8601 }.to_json
  end
end
