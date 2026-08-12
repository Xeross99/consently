module Consently
  # One <script> a provider wants on the page - either an external file or an
  # inline body. Keeping it as data rather than as HTML is what lets the view
  # render the very same script either live or blocked, without the provider
  # knowing which of the two happened.
  Script = Struct.new(:src, :inline, :async, :defer, :data, keyword_init: true) do
    def external?
      src.present?
    end

    # Extra data-* attributes some vendors configure the tag with, e.g.
    # Plausible's data-domain.
    def data_attributes
      data || {}
    end
  end
end
