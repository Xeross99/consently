require "rails/generators/base"

module Consently
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates the Consently initializer and wires the banner controller up."

      def create_initializer
        template "consently.rb", "config/initializers/consently.rb"
      end

      # Stimulus is how the banner releases the blocked tags, so registering
      # the controller is part of installing, not a step in a README nobody
      # reads.
      def register_stimulus_controller
        index = "app/javascript/controllers/index.js"
        return say_status :skip, "#{index} not found - register consently-banner yourself", :yellow unless File.exist?(index)

        append_to_file index, <<~JS

          import ConsentlyBannerController from "consently/banner_controller"
          import ConsentlyEmbedController from "consently/embed_controller"
          application.register("consently-banner", ConsentlyBannerController)
          application.register("consently-embed", ConsentlyEmbedController)
        JS
      end

      def show_readme
        say <<~TEXT

          Consently is installed. One thing left - put the helpers in your layout:

            <head>  <%= consently_tags %>
            <body>  <%= consently_noscript_tags %> ... <%= consently_banner %>

          The banner brings its own CSS; restyle it with the custom properties
          on .consently, or run `rails g consently:views` to take the markup over.

          Consent logging (optional): rails g consently:consent_log
        TEXT
      end
    end
  end
end
