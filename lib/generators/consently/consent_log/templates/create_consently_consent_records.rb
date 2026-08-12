class CreateConsentlyConsentRecords < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :consently_consent_records do |t|
      t.string :categories, null: false, default: ""
      t.string :consent_version, null: false
      t.string :subject
      t.string :scope
      t.string :user_agent
      # A salted digest rather than the address itself: enough to tell two
      # decisions apart, not enough to identify anyone.
      t.string :ip_hash

      t.datetime :created_at, null: false
    end

    add_index :consently_consent_records, :created_at
    add_index :consently_consent_records, :consent_version
  end
end
