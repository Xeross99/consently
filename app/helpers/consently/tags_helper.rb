module Consently
  # The three helpers a host application calls: the tags in <head>, the
  # noscript fallbacks right after <body>, and the banner anywhere on the page.
  module TagsHelper
    # Every tag configured for this request. Tags whose category the visitor
    # has not agreed to are rendered inert (type="text/plain") and the banner
    # turns them into real scripts the moment consent is given - so a visitor
    # who accepts does not have to reload to be counted.
    def consently_tags
      return "".html_safe unless consently_enabled?

      parts = []
      parts << consently_stylesheet_tag if Consently.config.stylesheet
      parts << consently_consent_mode_tag if Consently.config.google_consent_mode
      Consently.tags_for(request).each do |provider|
        provider.scripts.each { |script| parts << consently_script_tag(script, provider, consently_release?(provider)) }
      end

      safe_join(parts, "\n")
    end

    # Goes directly after <body> - Google Tag Manager and Meta both still ship
    # a noscript fallback. Only rendered for categories already granted: there
    # is no way to hold an iframe back and release it later.
    def consently_noscript_tags
      return "".html_safe unless consently_enabled?

      fallbacks = Consently.tags_for(request).filter_map do |provider|
        next unless consently_consent.granted?(provider.category)

        provider.noscript&.html_safe
      end
      return "".html_safe if fallbacks.empty?

      content_tag(:noscript, safe_join(fallbacks, "\n"))
    end

    # The banner, the preferences panel, and the JavaScript that releases the
    # blocked tags. Render it once per page, ideally at the end of the body.
    #
    # The container stays in the DOM after a choice is made so that
    # `consently_preferences_link` has something to reopen.
    def consently_banner(policy_url: nil)
      return "".html_safe unless consently_enabled? && Consently.consent_required?(request)

      render "consently/banner",
        consent: consently_consent,
        policy_url: policy_url || consently_policy_url,
        categories: Consently.config.optional_categories
    end

    # A "Cookie settings" link for the footer. Reopens the panel.
    #
    # Marked rather than wired: the link lives outside the banner element, so
    # a data-action on it would never bind. The controller watches the whole
    # document for a click on anything carrying this attribute, which also
    # means your own markup can reopen the panel just by wearing it.
    def consently_preferences_link(name = nil, **options, &block)
      name ||= t("consently.preferences_link")
      options[:data] = { consently_open: true }.merge(options[:data] || {})

      link_to(name, "#consently", options, &block)
    end

    def consently_consent
      @consently_consent ||= if Consently.consent_required?(request)
        Consent.from_cookie(
          cookies[Consently.config.cookie_name],
          version: Consently.config.consent_version,
          max_age: Consently.config.consent_max_age
        )
      else
        # Nobody to ask, so nothing is held back.
        Consent.new(categories: Consently.config.categories, version: Consently.config.consent_version)
      end
    end

    # Push an event onto the dataLayer from a view, respecting consent: with
    # no analytics consent the event is simply not emitted.
    #
    #   <%= consently_data_layer_push("newsletter_signup", source: "footer") %>
    def consently_data_layer_push(event, category: :analytics, **payload)
      return "".html_safe unless consently_enabled? && consently_consent.granted?(category)

      payload = payload.merge(event: event)
      consently_inline_script "window.dataLayer = window.dataLayer || []; window.dataLayer.push(#{payload.to_json});"
    end

    # A GA4 ecommerce event in the shape Google expects, from whatever your
    # models happen to look like:
    #
    #   <%= consently_ecommerce("purchase", items: @order.line_items,
    #         value: @order.total, currency: "EUR", transaction_id: @order.number) %>
    #
    # Items may be hashes already in GA4 shape, or any object answering to a
    # few obvious names (id/sku, name, price, quantity, category, brand,
    # variant) - a LineItem or a Product usually does.
    #
    # The previous ecommerce object is cleared first, as Google asks, so two
    # events on one page cannot bleed into each other.
    def consently_ecommerce(event, items: [], category: :analytics, **params)
      return "".html_safe unless consently_enabled? && consently_consent.granted?(category)

      ecommerce = params.merge(items: Array(items).map { |item| consently_ecommerce_item(item) })
      payload = { event: event, ecommerce: ecommerce.compact }

      consently_inline_script <<~JS.strip
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push(#{payload.to_json});
      JS
    end

    # A complete cookie policy for the tags this request would load: every
    # category, every vendor, every cookie it sets and for how long, plus
    # whether the visitor has agreed to it right now.
    #
    # Drop it into your own policy page under your own heading and legal text.
    def consently_policy
      render "consently/policy", tags: Consently.tags_for(request), consent: consently_consent
    end

    # An embedded video or map that waits for consent. Blocking scripts is
    # only half the job: a YouTube iframe sets cookies all by itself.
    #
    #   <%= consently_embed :youtube, "dQw4w9WgXcQ" %>
    #   <%= consently_embed :vimeo, "76979871", category: :analytics %>
    #   <%= consently_embed :google_maps, "Bahnhofstrasse 12, Berlin" %>
    #   <%= consently_embed :custom, "https://example.com/widget", title: "Widget" %>
    #
    # Until the category is granted the visitor sees a placeholder with a
    # button that opens the preferences panel; the iframe appears the moment
    # they agree, without a reload.
    def consently_embed(kind, identifier, category: :marketing, title: nil, ratio: "16 / 9", **iframe_options)
      src = consently_embed_src(kind, identifier)
      return "".html_safe if src.blank?

      render "consently/embed",
        src: src,
        title: title || t("consently.embed.title_#{kind}", default: t("consently.embed.title_default")),
        category: category.to_sym,
        ratio: ratio,
        granted: consently_consent.granted?(category),
        iframe_options: iframe_options
    end

    # The banner brings its own plain CSS - no framework, no build step. The
    # look is driven by custom properties, so overriding a few variables is
    # usually enough; `rails g consently:views` is there for the rest.
    def consently_stylesheet_tag
      stylesheet_link_tag "consently", media: "all"
    end

    # Where the banner POSTs the decision, when consent logging is on and the
    # engine is mounted. Nil otherwise, and the banner skips the request.
    def consently_log_url
      return nil unless Consently.config.log_consents

      consently.consents_path
    rescue NoMethodError, NameError
      nil
    end

    private

    def consently_enabled?
      Consently.enabled?(request)
    end

    # Whether this tag may run now. Normally that means consent; under
    # advanced consent mode Google's own tags also load before it, having
    # been told to store nothing until it arrives.
    def consently_release?(provider)
      return true if consently_consent.granted?(provider.category)

      Consently.config.advanced_google_consent_mode? && provider.google?
    end

    # Google's consent mode v2 defaults. This one is never blocked: its whole
    # job is to tell Google's tags that they may not store anything yet, and
    # it has to be on the page before them.
    def consently_consent_mode_tag
      analytics = consently_consent.granted?(:analytics) ? "granted" : "denied"
      marketing = consently_consent.granted?(:marketing) ? "granted" : "denied"

      consently_inline_script <<~JS
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('consent', 'default', {
          'ad_storage': 'denied',
          'ad_user_data': 'denied',
          'ad_personalization': 'denied',
          'analytics_storage': 'denied',
          'functionality_storage': 'granted',
          'security_storage': 'granted',
          'wait_for_update': 500
        });
        #{"gtag('consent', 'update', { 'analytics_storage': '#{analytics}', 'ad_storage': '#{marketing}', 'ad_user_data': '#{marketing}', 'ad_personalization': '#{marketing}' });" if consently_consent.given?}
      JS
    end

    # A bare id is enough for the vendors people embed most; anything else
    # takes a full URL.
    def consently_embed_src(kind, identifier)
      identifier = identifier.to_s
      return identifier if identifier.start_with?("http")

      case kind.to_sym
      when :youtube then "https://www.youtube-nocookie.com/embed/#{u(identifier)}"
      when :vimeo then "https://player.vimeo.com/video/#{u(identifier)}"
      when :google_maps then "https://www.google.com/maps?q=#{u(identifier)}&output=embed"
      end
    end

    # Whatever the application handed us, in the shape GA4 reads. Hashes pass
    # through (with symbol keys stringified by to_json anyway); objects are
    # asked for the handful of names that carry the same meaning everywhere.
    def consently_ecommerce_item(item)
      return item.compact if item.is_a?(Hash)

      {
        item_id: consently_first_value(item, :item_id, :sku, :id),
        item_name: consently_first_value(item, :item_name, :name, :title),
        price: consently_first_value(item, :price, :unit_price, :price_eur),
        quantity: consently_first_value(item, :quantity, :qty),
        item_category: consently_first_value(item, :item_category, :category),
        item_brand: consently_first_value(item, :item_brand, :brand),
        item_variant: consently_first_value(item, :item_variant, :variant)
      }.compact
    end

    def consently_first_value(item, *names)
      names.each do |name|
        next unless item.respond_to?(name)

        value = item.public_send(name)
        return value.respond_to?(:name) ? value.name : value if value.present?
      end

      nil
    end

    # A plain <script> with the JS as written. javascript_tag would wrap it in
    # a CDATA comment nobody has needed since XHTML.
    def consently_inline_script(javascript)
      attributes = {}
      attributes[:nonce] = content_security_policy_nonce if content_security_policy_nonce.present?

      content_tag(:script, javascript.html_safe, attributes)
    end

    def consently_policy_url
      url = Consently.config.policy_url
      url.respond_to?(:call) ? url.call(self) : url
    end

    def consently_script_tag(script, provider, granted)
      attributes = { data: { "consently-category" => provider.category }.merge(script.data_attributes) }
      attributes[:nonce] = content_security_policy_nonce if content_security_policy_nonce.present?

      if granted
        attributes[:src] = script.src if script.external?
        attributes[:async] = true if script.async
        attributes[:defer] = true if script.defer
        content_tag(:script, script.inline&.html_safe, attributes)
      else
        # Inert until the visitor agrees: browsers neither execute nor fetch a
        # script of an unknown type, and the src lives in a data attribute so
        # it is not even requested.
        attributes[:type] = "text/plain"
        attributes[:data]["consently-src"] = script.src if script.external?
        attributes[:data]["consently-async"] = "true" if script.async
        attributes[:data]["consently-defer"] = "true" if script.defer
        content_tag(:script, script.inline&.html_safe, attributes)
      end
    end
  end
end
