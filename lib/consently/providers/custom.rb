module Consently
  module Providers
    # The escape hatch for a vendor Consently does not know about yet. Blocked
    # and released exactly like a built-in one.
    #
    #   c.tag :custom, as: :piwik, category: :analytics,
    #         src: "https://cdn.example.com/piwik.js"
    #
    #   c.tag :custom, as: :whatever, category: :marketing, inline: <<~JS
    #     console.log("hello");
    #   JS
    class Custom < Base
      self.provider_key = :custom
      self.default_category = :marketing

      def scripts
        [ Script.new(src: options[:src], inline: options[:inline], async: options.fetch(:async, true), data: options[:data]) ]
      end

      def noscript
        options[:noscript]
      end

      private

      def validate!
        if options[:src].blank? && options[:inline].blank?
          raise MissingOption, "Consently: a :custom tag needs src: or inline:"
        end
        raise MissingOption, "Consently: a :custom tag needs as: to name it" if options[:as].blank?
      end
    end
  end
end
