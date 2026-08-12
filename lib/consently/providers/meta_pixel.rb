module Consently
  module Providers
    class MetaPixel < Base
      self.provider_key = :meta_pixel
      self.default_category = :marketing

      cookie "_fbp", days: 90
      cookie "fr", days: 90

      def scripts
        [ Script.new(inline: <<~JS.strip) ]
          !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
          n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
          n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
          t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,
          document,'script','https://connect.facebook.net/en_US/fbevents.js');
          fbq('init', '#{id}');
          fbq('track', 'PageView');
        JS
      end

      def noscript
        %(<img height="1" width="1" style="display:none" alt="" src="https://www.facebook.com/tr?id=#{id}&ev=PageView&noscript=1">)
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
