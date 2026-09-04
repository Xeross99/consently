require "active_support/core_ext/object/json"

module Consently
  # One analytics event on its way to the page: a name, a payload, and whether
  # it is a GA4 ecommerce event. It is written as JavaScript for whichever
  # transport the page runs on - gtag('event', ...) for gtag.js, a dataLayer
  # push for Google Tag Manager - so the helpers never have to know which.
  class Event
    TRANSPORTS = %i[gtag data_layer].freeze

    attr_reader :name, :payload

    def initialize(name, payload = {}, ecommerce: false)
      @name = name.to_s
      @payload = payload.to_h.compact
      @ecommerce = ecommerce
    end

    def ecommerce?
      @ecommerce
    end

    def to_js(transport)
      case transport.to_sym
      when :gtag then gtag_js
      when :data_layer then data_layer_js
      else raise ArgumentError, "Consently: unknown event transport #{transport.inspect}, expected one of #{TRANSPORTS.join(", ")}"
      end
    end

    private

    # gtag.js reads the dataLayer as a queue, so an event pushed before the
    # tag has loaded is not lost. That is what lets a released event fire the
    # moment consent arrives, while gtag.js is still on its way.
    def gtag_js
      "window.dataLayer = window.dataLayer || []; " \
        "window.gtag = window.gtag || function(){dataLayer.push(arguments);}; " \
        "gtag('event', #{name.to_json}, #{payload.to_json});"
    end

    def data_layer_js
      if ecommerce?
        # Cleared first, as Google asks, so two events on one page cannot
        # bleed into each other.
        "window.dataLayer = window.dataLayer || []; " \
          "window.dataLayer.push({ ecommerce: null }); " \
          "window.dataLayer.push(#{{ event: name, ecommerce: payload }.to_json});"
      else
        "window.dataLayer = window.dataLayer || []; window.dataLayer.push(#{payload.merge(event: name).to_json});"
      end
    end
  end
end
