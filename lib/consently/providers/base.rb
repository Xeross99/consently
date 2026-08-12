module Consently
  module Providers
    # A tag vendor: what scripts it needs and which consent category it falls
    # under. Subclasses describe the snippet as data (see Consently::Script)
    # so the view can render it live or blocked from the same description.
    class Base
      # Ids are interpolated straight into JavaScript, so they are held to a
      # shape that cannot carry a quote or a bracket out of the string.
      SAFE_OPTION = /\A[\w\-.:\/]+\z/

      class << self
        def registry
          @@registry ||= {}
        end

        def register(key, klass)
          registry[key.to_sym] = klass
        end

        def build(key, **options)
          klass = registry[key.to_sym] or raise UnknownProvider, key
          klass.new(**options)
        end

        # Set by each subclass; where a vendor is unambiguous (Plausible does
        # not touch cookies) it can say :necessary and load right away.
        attr_accessor :default_category

        def provider_key
          @provider_key
        end

        def provider_key=(key)
          @provider_key = key.to_sym
          register(@provider_key, self)
        end

        # What this vendor stores in the visitor's browser, for the policy
        # page. `days: nil` means a session cookie.
        def cookie(name, days: nil)
          cookie_manifest << { name: name, days: days }
        end

        def cookie_manifest
          @cookie_manifest ||= []
        end
      end

      attr_reader :options, :category, :key

      def initialize(**options)
        @options = options
        @category = (options[:category] || self.class.default_category).to_sym
        @key = (options[:as] || self.class.provider_key).to_sym
        validate!
      end

      # Array<Consently::Script>
      def scripts
        []
      end

      # Array<Consently::Cookie> - what this tag leaves in the browser.
      def cookies
        self.class.cookie_manifest.map { |attributes| Cookie.new(**attributes, provider: key) }
      end

      # Rendered inside <body>, for vendors that still ship a <noscript>
      # fallback (Google Tag Manager, Meta). HTML string or nil.
      def noscript
        nil
      end

      def to_s
        "#{key} (#{category})"
      end

      private

      def validate!
        # Subclasses call require_option for what they cannot work without.
      end

      def require_option(name)
        value = options[name]
        raise MissingOption, "Consently: #{self.class.provider_key} needs a #{name}:" if value.blank?
        unless value.to_s.match?(SAFE_OPTION)
          raise MissingOption, "Consently: #{name}: #{value.inspect} for #{self.class.provider_key} contains characters that are not allowed in a tag id"
        end

        value.to_s
      end
    end
  end
end
