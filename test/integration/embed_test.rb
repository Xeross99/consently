require "test_helper"

# A YouTube iframe sets cookies without any script of ours, so it has to wait
# the same way a tag does.
class EmbedTest < ActionDispatch::IntegrationTest
  setup { Consently.reset! }
  teardown { Consently.reset! }

  test "the iframe is not on the page until its category is granted" do
    get "/embeds"

    assert_select "iframe", false
    assert_select "[data-controller='consently-embed'][data-consently-embed-src-value*='youtube-nocookie']"
    assert_select "[data-consently-embed-target='placeholder']"
    # Nothing is requested from the vendor: the address is data, not a src.
    assert_no_match(/ src=["']https:\/\/www\.youtube/, response.body)
  end

  test "the iframe is rendered by the server once consent is in the cookie" do
    cookies[Consently.config.cookie_name] =
      { v: 1, c: [ "marketing" ], t: Time.current.iso8601 }.to_json

    get "/embeds"

    assert_select "iframe.consently-embed__frame[src*='youtube-nocookie']"
    assert_select "[data-consently-embed-target='placeholder'].consently-hidden"
  end

  test "each vendor gets the address it actually embeds from" do
    get "/embeds"

    assert_select "[data-consently-embed-src-value='https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ']"
    assert_select "[data-consently-embed-src-value='https://player.vimeo.com/video/76979871']"
    assert_select "[data-consently-embed-src-value*='maps?q=Bahnhofstrasse']"
    assert_select "[data-consently-embed-src-value='https://example.com/widget']"
  end

  test "an embed can wait for a category of its own" do
    get "/embeds"

    assert_select "[data-consently-embed-category-value='analytics'][data-consently-embed-src-value*='vimeo']"
  end

  test "the placeholder says which consent is missing and offers the panel" do
    get "/embeds"

    assert_match "Marketing", response.body
    assert_select "[data-consently-embed-target='placeholder'] button[data-consently-open]"
  end
end
