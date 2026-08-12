require "rails/generators/base"
require "rails/generators/active_record"

module Consently
  module Generators
    class ConsentLogGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Adds the table behind Consently::ConsentRecord, for proof of consent."

      def create_migration_file
        migration_template "create_consently_consent_records.rb", "db/migrate/create_consently_consent_records.rb"
      end

      def show_next_steps
        say <<~TEXT

          Next:
            1. rails db:migrate
            2. mount Consently::Engine => "/consently"   # config/routes.rb
            3. c.log_consents = true                     # config/initializers/consently.rb
        TEXT
      end
    end
  end
end
