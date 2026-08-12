module Consently
  module Providers
    # Cookieless, and often run without a banner at all - but whether that is
    # allowed is a legal call, not ours, so it waits for consent like any
    # other analytics tag. Move it with category: :necessary if your legal
    # advice says it may run right away.
    class Plausible < Base
      self.provider_key = :plausible
      self.default_category = :analytics

      def scripts
        [ Script.new(src: "#{host}/js/script.js", defer: true, data: { "domain" => domain }) ]
      end

      private

      def domain
        @domain ||= require_option(:domain)
      end

      def host
        @host ||= options.fetch(:host, "https://plausible.io").to_s.chomp("/")
      end

      def validate!
        domain
      end
    end
  end
end
