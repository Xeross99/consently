module Consently
  # What the visitor has agreed to, as read from the cookie.
  #
  # The cookie is deliberately tiny and readable by JavaScript - the banner
  # writes it in the browser and the server only reads it, so a page rendered
  # after the choice can emit the real tags instead of blocked ones.
  #
  #   {"v":1,"c":["analytics"],"t":"2026-08-12T10:00:00Z"}
  class Consent
    NECESSARY = :necessary

    attr_reader :categories, :version, :recorded_at

    def self.none
      new(given: false)
    end

    # Never raises: a cookie can be truncated, hand-edited or left over from an
    # older format, and none of that should take a page down.
    def self.from_cookie(raw, version:)
      return none if raw.blank?

      data = begin
        JSON.parse(raw.to_s)
      rescue JSON::ParserError
        nil
      end
      return none unless data.is_a?(Hash)

      # A consent given against an older policy version counts as no consent:
      # the banner asks again and nothing runs in the meantime.
      return none unless data["v"].to_s == version.to_s

      new(
        categories: Array(data["c"]).map { |category| category.to_s.to_sym },
        version: data["v"],
        recorded_at: data["t"]
      )
    end

    def initialize(categories: [], version: nil, recorded_at: nil, given: true)
      @categories = Array(categories).map(&:to_sym).freeze
      @version = version
      @recorded_at = recorded_at
      @given = given
    end

    def given?
      @given
    end

    # Necessary tags are the ones the site cannot work without, so they never
    # wait for a click.
    def granted?(category)
      category.to_sym == NECESSARY || categories.include?(category.to_sym)
    end

    def to_h
      { "v" => version, "c" => categories.map(&:to_s), "t" => recorded_at }
    end
  end
end
