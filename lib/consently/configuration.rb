module Consently
  # Everything the host application sets in config/initializers/consently.rb.
  class Configuration
    DEFAULT_CATEGORIES = %i[necessary analytics marketing].freeze

    # Where the visitor's choice is kept. It is read by JavaScript, so it is a
    # plain cookie rather than a signed one.
    #
    # Set cookie_domain to ".example.com" when the site spans subdomains -
    # without it a consent given on www does not count on shop.
    attr_accessor :cookie_name, :cookie_max_age, :cookie_path, :cookie_domain

    # How long a consent stays valid, regardless of the cookie's own lifetime.
    # Guidance across the EU converges on asking again about once a year; nil
    # leaves the cookie to expire on its own.
    attr_accessor :consent_max_age

    # Bump this whenever the policy changes: an older consent stops counting
    # and the banner asks again.
    attr_accessor :consent_version

    # true, false, or a callable taking the request - e.g.
    #   c.enabled = ->(request) { Rails.env.production? }
    attr_accessor :enabled

    # Google's consent mode v2. Three settings:
    #
    #   :basic     - defaults denied, and Google's own tags stay blocked until
    #                the visitor agrees. Nothing about them reaches Google
    #                before consent. The default, and the strict reading.
    #   :advanced  - defaults denied, but Google's tags load right away and
    #                send cookieless pings, which is what lets Google Ads
    #                model the conversions of visitors who said no. More data,
    #                and a request to Google either way - ask your lawyer.
    #   false      - no consent mode at all.
    #
    # `true` is read as :basic.
    attr_reader :google_consent_mode

    def google_consent_mode=(mode)
      @google_consent_mode = case mode
      when true, :basic then :basic
      when :advanced then :advanced
      when false, nil then false
      else raise ArgumentError, "google_consent_mode must be :basic, :advanced or false"
      end
    end

    def advanced_google_consent_mode?
      google_consent_mode == :advanced
    end

    # Store a row per decision, as proof of consent. Needs the engine mounted
    # and the migration from `rails g consently:consent_log`.
    attr_accessor :log_consents

    # Whether consently_tags links the banner's stylesheet. Turn it off if
    # you have taken the views over and styled them yourself.
    attr_accessor :stylesheet

    # Honour the browser's Do Not Track header as a rejection. Off by default:
    # DNT is advisory and widely ignored, so treating it as a legal signal is
    # your call, not the gem's.
    attr_accessor :respect_do_not_track

    # Global Privacy Control, which - unlike DNT - is a binding opt-out signal
    # in California and Colorado. On by default, and a visitor who sends it is
    # never shown the banner: their answer already arrived.
    attr_accessor :respect_global_privacy_control

    # Whether this visitor has to be asked at all. false means no banner and
    # everything runs - the answer for traffic outside the EU when your legal
    # advice says so:
    #
    #   c.consent_required = ->(request) { EU_COUNTRIES.include?(request.headers["CF-IPCountry"]) }
    #
    # Careful: this switches tags on without asking, so it is opt-in.
    attr_accessor :consent_required

    # Reload the page once a choice is made. Off by default - releasing the
    # blocked tags in place is the whole point, and a reload throws away
    # whatever the visitor was doing. Turn it on when the page itself renders
    # differently depending on consent (an embedded map, a video, a status
    # list) and you would rather let the server decide again.
    attr_accessor :reload_after_choice

    # Who made the decision, for the consent log. A callable taking the
    # request; return anything that identifies the visitor in your own system
    # (a global id, "User#42", an account number). Left nil the log stays
    # anonymous, which is the right default for a public site.
    attr_accessor :consent_subject

    # Where the cookie policy lives. A string, or a callable taking the view
    # context - handy when the URL is locale dependent.
    attr_accessor :policy_url

    # Which scope a request belongs to, e.g. ->(request) { request.host }.
    # Nil means every request sees the default configuration.
    attr_accessor :scope_resolver

    attr_reader :categories

    def initialize
      @cookie_name = "consently"
      @cookie_max_age = 60 * 60 * 24 * 180 # six months, the usual guidance
      @cookie_path = "/"
      @cookie_domain = nil
      @consent_max_age = nil
      @consent_version = 1
      @enabled = true
      @google_consent_mode = :basic
      @stylesheet = true
      @log_consents = false
      @respect_do_not_track = false
      @respect_global_privacy_control = true
      @consent_required = true
      @reload_after_choice = false
      @consent_subject = nil
      @policy_url = nil
      @scope_resolver = nil
      @categories = DEFAULT_CATEGORIES.dup
      @scopes = {}
    end

    # A category of your own, shown in the preferences panel alongside the
    # built-in ones. Give it a name in your locale file.
    def category(name)
      name = name.to_sym
      @categories << name unless @categories.include?(name)
      name
    end

    def optional_categories
      categories - [ Consent::NECESSARY ]
    end

    # c.tag :google_analytics, id: "G-XXXX"
    def tag(key, **options)
      default_scope.tag(key, **options)
    end

    # Tags for one shop, host or whatever your scope_resolver returns. Falls
    # back to the tags declared outside any scope, and may override them by
    # declaring the same provider again.
    #
    #   c.scope "shop.example.com" do |s|
    #     s.tag :google_analytics, id: "G-SHOP00001"
    #   end
    def scope(name)
      scope = (@scopes[name.to_s] ||= Scope.new)
      yield scope if block_given?
      scope
    end

    def tags_for(scope_name = nil)
      tags = default_scope.tags.dup
      tags.merge!(@scopes[scope_name.to_s].tags) if scope_name && @scopes.key?(scope_name.to_s)
      tags.values
    end

    def default_scope
      @default_scope ||= Scope.new
    end

    # A named bundle of tags. Same API as the top-level `tag`, which is what
    # makes the block form read the way it does.
    class Scope
      def initialize
        @tags = {}
      end

      def tag(key, **options)
        provider = Providers::Base.build(key, **options)
        @tags[provider.key] = provider
      end

      def tags
        @tags
      end
    end
  end
end
