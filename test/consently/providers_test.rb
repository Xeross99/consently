require "test_helper"

module Consently
  class ProvidersTest < ActiveSupport::TestCase
    test "an unknown provider says what it does know" do
      error = assert_raises(UnknownProvider) { Providers::Base.build(:matomo, id: "1") }

      assert_match "google_analytics", error.message
    end

    test "a tag without its id is refused at boot rather than silently doing nothing" do
      assert_raises(MissingOption) { Providers::Base.build(:google_analytics) }
      assert_raises(MissingOption) { Providers::Base.build(:clarity, id: "") }
    end

    test "an id that could break out of the snippet is refused" do
      assert_raises(MissingOption) { Providers::Base.build(:google_analytics, id: "G-1'); alert(1); //") }
    end

    test "google analytics loads the library and configures it" do
      scripts = Providers::Base.build(:google_analytics, id: "G-ABC").scripts

      assert_equal "https://www.googletagmanager.com/gtag/js?id=G-ABC", scripts.first.src
      assert scripts.first.async
      assert_match "gtag('config', 'G-ABC'", scripts.last.inline
      assert_match "anonymize_ip", scripts.last.inline
    end

    test "ip anonymisation can be turned off" do
      scripts = Providers::Base.build(:google_analytics, id: "G-ABC", anonymize: false).scripts

      assert_no_match(/anonymize_ip/, scripts.last.inline)
    end

    test "tag manager brings its noscript iframe" do
      provider = Providers::Base.build(:google_tag_manager, id: "GTM-ABC")

      assert_match "gtm.js?id=", provider.scripts.sole.inline
      assert_match "ns.html?id=GTM-ABC", provider.noscript
    end

    test "plausible waits for consent by default, cookieless or not" do
      provider = Providers::Base.build(:plausible, domain: "example.com")

      assert_equal :analytics, provider.category
      assert_equal({ "domain" => "example.com" }, provider.scripts.sole.data_attributes)
    end

    test "plausible can be told to run right away" do
      provider = Providers::Base.build(:plausible, domain: "example.com", category: :necessary)

      assert_equal :necessary, provider.category
    end

    test "a category can be moved" do
      assert_equal :marketing, Providers::Base.build(:clarity, id: "abc", category: :marketing).category
    end

    test "hotjar needs a numeric id, because its snippet does not quote it" do
      assert_raises(MissingOption) { Providers::Base.build(:hotjar, id: "abc") }
      assert_match "hjid:123", Providers::Base.build(:hotjar, id: 123).scripts.sole.inline
    end

    test "a custom tag needs a name and something to load" do
      assert_raises(MissingOption) { Providers::Base.build(:custom, src: "https://example.com/t.js") }
      assert_raises(MissingOption) { Providers::Base.build(:custom, as: :thing) }

      provider = Providers::Base.build(:custom, as: :thing, src: "https://example.com/t.js")

      assert_equal :thing, provider.key
    end
  end
end
