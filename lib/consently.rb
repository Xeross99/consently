require "json"
require "time"
require "active_support"
require "active_support/core_ext/object/blank"

require "consently/version"
require "consently/script"
require "consently/cookie"
require "consently/consent"
require "consently/event"
require "consently/providers/base"
require "consently/providers"
require "consently/configuration"
require "consently/engine" if defined?(Rails::Engine)

# Tag snippets and cookie consent in one place.
#
# Everything the host application needs goes through `Consently.configure`;
# the views ask this module what to render for the current request.
module Consently
  class Error < StandardError; end

  # A provider key that was never registered - almost always a typo in the
  # initializer, so the message lists what is available.
  class UnknownProvider < Error
    def initialize(key)
      super("Unknown Consently provider #{key.inspect}. Available: #{Providers::Base.registry.keys.sort.join(", ")}")
    end
  end

  class MissingOption < Error; end

  class << self
    def configure
      yield config
      config
    end

    def config
      @config ||= Configuration.new
    end

    # Mostly for tests and for reloading an initializer in development.
    def reset!
      @config = Configuration.new
    end

    # Tags configured for this request: the defaults, plus whatever the
    # matching scope adds or overrides.
    def tags_for(request = nil)
      config.tags_for(scope_for(request))
    end

    def scope_for(request)
      return nil unless config.scope_resolver && request

      config.scope_resolver.call(request)
    end

    def enabled?(request = nil)
      resolve(config.enabled, request)
    end

    # How events reach Google for this request. Google Tag Manager reads
    # dataLayer pushes; gtag.js only acts on gtag('event', ...) calls, and a
    # push meant for a container it silently ignores. :auto looks at the tags
    # in the request's scope: a container present means the dataLayer,
    # otherwise any Google tag means gtag.
    def event_transport_for(request = nil)
      return config.event_transport unless config.event_transport == :auto

      providers = tags_for(request)
      return :data_layer if providers.any? { |provider| provider.is_a?(Providers::GoogleTagManager) }

      providers.any?(&:google?) ? :gtag : :data_layer
    end

    # Whether this visitor has to be asked. When they do not, every category
    # counts as granted and no banner is rendered - see config.consent_required.
    def consent_required?(request = nil)
      resolve(config.consent_required, request)
    end

    private

    def resolve(setting, request)
      setting.respond_to?(:call) ? !!setting.call(request) : !!setting
    end
  end
end
