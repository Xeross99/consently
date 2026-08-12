module Consently
  # Proof that a visitor agreed to something, and to what. Optional: create it
  # with `rails g consently:consent_log` and switch config.log_consents on.
  class ConsentRecord < ApplicationRecord
    self.table_name = "consently_consent_records"

    scope :for_version, ->(version) { where(consent_version: version.to_s) }
    scope :in_scope, ->(scope) { where(scope: scope.to_s) }

    def categories
      self[:categories].to_s.split(",").map(&:to_sym)
    end

    def granted?(category)
      category.to_sym == Consent::NECESSARY || categories.include?(category.to_sym)
    end
  end
end
