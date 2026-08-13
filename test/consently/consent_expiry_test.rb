require "test_helper"

module Consently
  class ConsentExpiryTest < ActiveSupport::TestCase
    test "a consent older than the maximum age is asked for again" do
      cookie = { v: 1, c: [ "analytics" ], t: 13.months.ago.utc.iso8601 }.to_json

      assert_not Consent.from_cookie(cookie, version: 1, max_age: 12.months).given?
      assert Consent.from_cookie(cookie, version: 1, max_age: 24.months).given?
      assert Consent.from_cookie(cookie, version: 1).given?, "no maximum age means the cookie decides"
    end

    test "a consent without a readable timestamp is treated as too old" do
      [ nil, "", "whenever" ].each do |timestamp|
        cookie = { v: 1, c: [ "analytics" ], t: timestamp }.to_json

        assert_not Consent.from_cookie(cookie, version: 1, max_age: 12.months).given?,
          "#{timestamp.inspect} should not pass as a recent consent"
      end
    end

    test "a fresh consent is untouched by the maximum age" do
      cookie = { v: 1, c: [ "marketing" ], t: Time.current.utc.iso8601 }.to_json

      assert Consent.from_cookie(cookie, version: 1, max_age: 1.month).granted?(:marketing)
    end
  end
end
