Consently.configure do |c|
  # Where the tags run. Anything callable gets the request.
  c.enabled = ->(request) { Rails.env.production? }

  # Bump when your cookie policy changes: older consents stop counting and
  # the banner asks again.
  c.consent_version = 1

  # Link shown in the banner. A callable receives the view context, which is
  # what you want when the URL is locale dependent.
  # c.policy_url = -> (view) { view.main_app.cookie_policy_path }

  # Reload the page once a choice is made. Off by default: the tags start
  # running in place, so there is nothing to reload for. Turn it on if the
  # page renders differently depending on consent.
  # c.reload_after_choice = true

  # Whether this visitor has to be asked at all. Return false and nothing is
  # held back and no banner is shown - for traffic outside the EU, if your
  # legal advice says so.
  # c.consent_required = ->(request) { EU.include?(request.headers["CF-IPCountry"]) }

  # Global Privacy Control (binding in California and Colorado) counts as a
  # rejection and is honoured by default. Do Not Track is advisory, so it is
  # not - switch it on if you want it treated the same way.
  # c.respect_do_not_track = true

  # Google consent mode v2: defaults denied before any Google tag, updated
  # when the visitor chooses. Leave on if you use anything Google.
  c.google_consent_mode = true

  # Store a row per decision as proof of consent. Needs the migration from
  # `rails g consently:consent_log` and the engine mounted in routes.rb:
  #   mount Consently::Engine => "/consently"
  # c.log_consents = true
  #
  # The log is anonymous unless you say who made the decision:
  # c.consent_subject = ->(request) { request.env["warden"]&.user&.id }

  # A category of your own, on top of :necessary, :analytics and :marketing.
  # c.category :personalization

  # Your tags. Each one waits for its category unless that category is
  # :necessary.
  # c.tag :google_tag_manager, id: "GTM-XXXXXXX"
  # c.tag :google_analytics,   id: "G-XXXXXXXXXX"
  # c.tag :clarity,            id: "xxxxxxxxxx"
  # c.tag :meta_pixel,         id: "000000000000000"
  # c.tag :hotjar,             id: 1234567
  # c.tag :plausible,          domain: "example.com"
  #
  # Anything else:
  # c.tag :custom, as: :piwik, category: :analytics, src: "https://cdn.example.com/piwik.js"

  # Different tags per domain, tenant or shop. Whatever the resolver returns
  # is matched against the scope names below; scopes inherit the tags above
  # and may override them by declaring the same provider again.
  # c.scope_resolver = ->(request) { request.host }
  #
  # c.scope "example.com" do |s|
  #   s.tag :google_analytics, id: "G-EXAMPLE"
  # end
end
