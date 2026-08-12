module Consently
  module Providers
    # Microsoft Clarity: session recordings and heatmaps.
    class Clarity < Base
      self.provider_key = :clarity
      self.default_category = :analytics

      cookie "_clck", days: 365
      cookie "_clsk", days: 1
      cookie "CLID", days: 365
      cookie "MUID", days: 390
      cookie "ANONCHK", days: nil

      def scripts
        [ Script.new(inline: <<~JS.strip) ]
          (function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
          t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
          y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
          })(window, document, "clarity", "script", "#{id}");
        JS
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
