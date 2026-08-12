module Consently
  # One cookie a tag is known to set. A cookie policy has to name them and say
  # how long they last, which is exactly the part everyone copies from a
  # competitor's site and gets wrong.
  #
  # `days` is nil for a session cookie.
  Cookie = Struct.new(:name, :days, :provider, keyword_init: true) do
    def session?
      days.nil?
    end
  end
end
