module Consently
  class Engine < ::Rails::Engine
    isolate_namespace Consently

    initializer "consently.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Consently::TagsHelper
      end
    end

    # The engine's app/assets comes along on its own; app/javascript does not,
    # and Sprockets needs the two entries named before it will compile them.
    initializer "consently.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        if app.config.assets.respond_to?(:precompile)
          app.config.assets.precompile += %w[consently.css consently/banner_controller.js consently/embed_controller.js consently/events.js]
        end
      end
    end

    # The banner controller gets pinned for the host application, so
    # `import "consently/banner_controller"` resolves without anyone editing
    # config/importmap.rb. Our paths have to be in place before importmap-rails
    # draws them, hence `before:`.
    initializer "consently.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end
  end
end
