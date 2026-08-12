require "test_helper"

module Consently
  class ConsentTest < ActiveSupport::TestCase
    test "no cookie means nothing has been agreed to" do
      consent = Consent.from_cookie(nil, version: 1)

      assert_not consent.given?
      assert_not consent.granted?(:analytics)
    end

    test "necessary is granted even without a cookie" do
      assert Consent.from_cookie(nil, version: 1).granted?(:necessary)
    end

    test "reads the categories out of the cookie" do
      consent = Consent.from_cookie({ v: 1, c: [ "analytics" ], t: "2026-08-12T10:00:00Z" }.to_json, version: 1)

      assert consent.given?
      assert consent.granted?(:analytics)
      assert_not consent.granted?(:marketing)
    end

    test "a consent given against an older policy version does not count" do
      cookie = { v: 1, c: [ "analytics", "marketing" ], t: "2026-08-12T10:00:00Z" }.to_json

      assert_not Consent.from_cookie(cookie, version: 2).given?
    end

    test "the version comparison survives a string on either side" do
      cookie = { v: "3", c: [ "analytics" ], t: nil }.to_json

      assert Consent.from_cookie(cookie, version: 3).granted?(:analytics)
    end

    test "a mangled cookie is treated as no consent rather than an error" do
      [ "not json at all", "[]", "{", "null", "" ].each do |raw|
        assert_not Consent.from_cookie(raw, version: 1).given?, "#{raw.inspect} should not count as consent"
      end
    end
  end
end
