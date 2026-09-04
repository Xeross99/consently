require "test_helper"

module Consently
  class EventTest < ActiveSupport::TestCase
    test "under gtag.js an event is a gtag('event') call" do
      js = Event.new("newsletter_signup", { source: "footer" }).to_js(:gtag)

      assert_match "gtag('event', \"newsletter_signup\", {\"source\":\"footer\"});", js
      # Defined if missing, so the call works before the GA snippet has run.
      assert_match "window.gtag = window.gtag || function(){dataLayer.push(arguments);};", js
    end

    test "under gtag.js an ecommerce event carries its items flat, the way GA4 reads them" do
      js = Event.new("purchase", { value: 9.99, items: [ { item_id: "A" } ] }, ecommerce: true).to_js(:gtag)

      assert_match "gtag('event', \"purchase\", {\"value\":9.99,\"items\":[{\"item_id\":\"A\"}]});", js
      assert_no_match(/ecommerce/, js)
    end

    test "under Google Tag Manager an event is a dataLayer push" do
      js = Event.new("newsletter_signup", { source: "footer" }).to_js(:data_layer)

      assert_match "window.dataLayer.push({\"source\":\"footer\",\"event\":\"newsletter_signup\"});", js
      assert_no_match(/gtag/, js)
    end

    test "under Google Tag Manager an ecommerce event clears the previous object first" do
      js = Event.new("purchase", { value: 9.99, items: [] }, ecommerce: true).to_js(:data_layer)

      assert_match "window.dataLayer.push({ ecommerce: null });", js
      assert_match "window.dataLayer.push({\"event\":\"purchase\",\"ecommerce\":{\"value\":9.99,\"items\":[]}});", js
    end

    test "nil values are dropped from the payload" do
      assert_equal({ source: "footer" }, Event.new("x", { source: "footer", coupon: nil }).payload)
    end

    test "a payload cannot break out of the script" do
      js = Event.new("x", { name: "</script><script>alert(1)</script>" }).to_js(:gtag)

      assert_no_match(%r{</script>}, js)
    end

    test "an unknown transport is refused" do
      assert_raises(ArgumentError) { Event.new("x").to_js(:carrier_pigeon) }
    end
  end
end
