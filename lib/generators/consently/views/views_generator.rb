require "rails/generators/base"

module Consently
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views/consently", __dir__)

      desc "Copies the banner markup into your app so you can restyle it."

      def copy_views
        directory ".", "app/views/consently"
      end
    end
  end
end
