require "test_helper"

class EcommerceTest < ActionDispatch::IntegrationTest
  # Whatever a shop happens to call its columns, GA4 wants the same seven
  # names - so the helper is tested against a plain object, not a hash.
  LineItem = Struct.new(:sku, :name, :price, :quantity, :category, keyword_init: true)

  setup do
    Consently.reset!
    Consently.configure { |c| c.tag :google_analytics, id: "G-TEST" }
  end

  teardown { Consently.reset! }

  test "an ecommerce event is not emitted without analytics consent" do
    get "/checkout"

    assert_no_match(/purchase/, response.body)
  end

  test "an ecommerce event carries the items in the shape GA4 reads" do
    consent_to "analytics"

    get "/checkout"

    assert_match "\"event\":\"purchase\"", response.body
    assert_match "\"transaction_id\":\"1234\"", response.body
    assert_match "\"item_id\":\"TB-001\"", response.body
    assert_match "\"item_name\":\"Straight track\"", response.body
    assert_match "\"quantity\":2", response.body
    assert_match "\"item_category\":\"Track\"", response.body
  end

  test "the previous ecommerce object is cleared first, as Google asks" do
    consent_to "analytics"

    get "/checkout"

    assert_match "window.dataLayer.push({ ecommerce: null });", response.body
  end

  test "a plain hash is passed through untouched" do
    consent_to "analytics"

    get "/checkout?hash=1"

    assert_match "\"item_id\":\"RAW-1\"", response.body
  end

  private

  def consent_to(*categories)
    cookies[Consently.config.cookie_name] =
      { v: Consently.config.consent_version, c: categories, t: Time.current.iso8601 }.to_json
  end
end
