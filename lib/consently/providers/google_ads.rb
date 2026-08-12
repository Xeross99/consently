module Consently
  module Providers
    class GoogleAds < Base
      self.provider_key = :google_ads
      self.default_category = :marketing

      cookie "_gcl_au", days: 90

      def scripts
        [
          Script.new(src: "https://www.googletagmanager.com/gtag/js?id=#{id}", async: true),
          Script.new(inline: <<~JS.strip)
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '#{id}');
          JS
        ]
      end

      private

      def id
        @id ||= require_option(:id)
      end

      def validate!
        id
      end
    end
  end
end
