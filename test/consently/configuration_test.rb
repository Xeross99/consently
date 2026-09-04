require "test_helper"

module Consently
  class ConfigurationTest < ActiveSupport::TestCase
    setup { Consently.reset! }
    teardown { Consently.reset! }

    test "tags declared outside a scope apply everywhere" do
      Consently.configure { |c| c.tag :google_analytics, id: "G-DEFAULT" }

      assert_equal [ :google_analytics ], Consently.config.tags_for(nil).map(&:key)
      assert_equal [ :google_analytics ], Consently.config.tags_for("anything").map(&:key)
    end

    test "a scope adds to the default tags" do
      Consently.configure do |c|
        c.tag :google_analytics, id: "G-DEFAULT"
        c.scope("trixbrix") { |s| s.tag :clarity, id: "abc" }
      end

      assert_equal %i[google_analytics clarity], Consently.config.tags_for("trixbrix").map(&:key)
      assert_equal %i[google_analytics], Consently.config.tags_for("pixelpicture").map(&:key)
    end

    test "a scope overrides a default tag by declaring the same provider" do
      Consently.configure do |c|
        c.tag :google_analytics, id: "G-DEFAULT"
        c.scope("trixbrix") { |s| s.tag :google_analytics, id: "G-TRIX" }
      end

      trixbrix = Consently.config.tags_for("trixbrix").sole

      assert_equal "G-TRIX", trixbrix.options[:id]
      assert_equal "G-DEFAULT", Consently.config.tags_for(nil).sole.options[:id]
    end

    test "two tags of the same provider live side by side when named apart" do
      Consently.configure do |c|
        c.tag :google_analytics, id: "G-ONE"
        c.tag :google_analytics, as: :secondary_analytics, id: "G-TWO"
      end

      assert_equal %i[google_analytics secondary_analytics], Consently.config.tags_for(nil).map(&:key)
    end

    test "the event transport follows the tags: a container means the dataLayer, gtag.js means gtag" do
      Consently.configure { |c| c.tag :google_analytics, id: "G-ONE" }
      assert_equal :gtag, Consently.event_transport_for(nil)

      Consently.configure { |c| c.tag :google_tag_manager, id: "GTM-ONE" }
      assert_equal :data_layer, Consently.event_transport_for(nil)
    end

    test "with no Google tag at all events go to the dataLayer" do
      Consently.configure { |c| c.tag :plausible, domain: "example.com" }

      assert_equal :data_layer, Consently.event_transport_for(nil)
    end

    test "the event transport is decided per scope" do
      Consently.configure do |c|
        c.scope_resolver = ->(request) { request }
        c.tag :google_analytics, id: "G-ONE"
        c.scope("with_container") { |s| s.tag :google_tag_manager, id: "GTM-ONE" }
      end

      assert_equal :gtag, Consently.event_transport_for("plain")
      assert_equal :data_layer, Consently.event_transport_for("with_container")
    end

    test "a forced event transport wins over the tags, and is validated where it is set" do
      Consently.configure do |c|
        c.tag :google_tag_manager, id: "GTM-ONE"
        c.event_transport = :gtag
      end

      assert_equal :gtag, Consently.event_transport_for(nil)
      assert_raises(ArgumentError) { Consently.config.event_transport = :smoke_signals }
    end

    test "custom categories join the optional ones" do
      Consently.configure { |c| c.category :personalization }

      assert_equal %i[analytics marketing personalization], Consently.config.optional_categories
    end

    test "enabled takes a callable and gets the request" do
      Consently.configure { |c| c.enabled = ->(request) { request == :yes } }

      assert Consently.enabled?(:yes)
      assert_not Consently.enabled?(:no)
    end

    test "the scope resolver decides which scope a request belongs to" do
      Consently.configure { |c| c.scope_resolver = ->(request) { request.upcase } }

      assert_equal "TRIXBRIX", Consently.scope_for("trixbrix")
    end
  end
end
