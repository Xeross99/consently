module Consently
  module Providers
    class GoogleTagManager < Base
      self.provider_key = :google_tag_manager
      self.default_category = :analytics

      # None of its own: whatever it loads brings its own cookies, so list
      # those tags here as well if you manage them through the container.

      def scripts
        [ Script.new(inline: <<~JS.strip) ]
          (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':new Date().getTime(),event:'gtm.js'});
          var f=d.getElementsByTagName(s)[0],j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';
          j.async=true;j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
          })(window,document,'script','dataLayer','#{id}');
        JS
      end

      def noscript
        %(<iframe src="https://www.googletagmanager.com/ns.html?id=#{id}" height="0" width="0" style="display:none;visibility:hidden"></iframe>)
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
