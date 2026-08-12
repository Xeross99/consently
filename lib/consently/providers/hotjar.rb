module Consently
  module Providers
    class Hotjar < Base
      self.provider_key = :hotjar
      self.default_category = :analytics

      cookie "_hjSessionUser_*", days: 365
      cookie "_hjSession_*", days: nil

      def scripts
        [ Script.new(inline: <<~JS.strip) ]
          (function(h,o,t,j,a,r){h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
          h._hjSettings={hjid:#{id},hjsv:#{version}};a=o.getElementsByTagName('head')[0];
          r=o.createElement('script');r.async=1;r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
          a.appendChild(r);})(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
        JS
      end

      private

      # Numeric on purpose: the snippet uses the id unquoted.
      def id
        @id ||= Integer(require_option(:id))
      rescue ArgumentError
        raise MissingOption, "Consently: hotjar id: must be a number"
      end

      # Hotjar's snippet version, not the site id; it has been 6 for years.
      def version
        Integer(options.fetch(:snippet_version, 6))
      end

      def validate!
        id
        version
      end
    end
  end
end
