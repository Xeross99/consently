module Consently
  module Providers
    # GA4. Pass `anonymize: false` to leave IP anonymisation off; it is on by
    # default because most European deployments want it.
    class GoogleAnalytics < Base
      self.provider_key = :google_analytics
      self.default_category = :analytics
      self.google = true

      # What GA4 leaves behind. The container-scoped one is written per
      # measurement id, hence the wildcard.
      cookie "_ga", days: 730
      cookie "_ga_*", days: 730
      cookie "_gid", days: 1
      cookie "_gat", days: nil

      def scripts
        [
          Script.new(src: "https://www.googletagmanager.com/gtag/js?id=#{id}", async: true),
          Script.new(inline: <<~JS.strip)
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '#{id}'#{config_options});
          JS
        ]
      end

      private

      def id
        @id ||= require_option(:id)
      end

      def config_options
        return "" unless options.fetch(:anonymize, true)

        ", { 'anonymize_ip': true }"
      end

      def validate!
        id
      end
    end
  end
end
