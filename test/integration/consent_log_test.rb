require "test_helper"

class ConsentLogTest < ActionDispatch::IntegrationTest
  setup do
    Consently.reset!
    Consently.configure { |c| c.log_consents = true }
    Consently::ConsentRecord.delete_all
  end

  teardown { Consently.reset! }

  test "a decision is recorded with what it covered and which policy it answered" do
    post "/consently/consents", params: { categories: %w[analytics marketing], version: "1" }, as: :json

    assert_response :no_content
    record = Consently::ConsentRecord.sole

    assert_equal %i[analytics marketing], record.categories
    assert_equal "1", record.consent_version
    assert record.granted?(:analytics)
    assert record.granted?(:necessary)
  end

  test "a rejection is a record too - that is the point of the log" do
    post "/consently/consents", params: { categories: [], version: "1" }, as: :json

    record = Consently::ConsentRecord.sole

    assert_empty record.categories
    assert_not record.granted?(:marketing)
  end

  test "the address is stored as a digest, never as itself" do
    post "/consently/consents", params: { categories: [ "analytics" ], version: "1" }, as: :json

    record = Consently::ConsentRecord.sole

    assert_equal 64, record.ip_hash.length
    assert_not_includes record.ip_hash, "127.0.0.1"
  end

  test "nobody is named unless the application says who they are" do
    post "/consently/consents", params: { categories: [ "analytics" ], version: "1" }, as: :json
    assert_nil Consently::ConsentRecord.sole.subject

    Consently.config.consent_subject = ->(_request) { "User#42" }
    post "/consently/consents", params: { categories: [ "analytics" ], version: "1" }, as: :json

    assert_equal "User#42", Consently::ConsentRecord.order(:id).last.subject
  end

  test "the scope is kept, so a decision can be told apart per shop" do
    Consently.config.scope_resolver = ->(request) { request.host }

    post "http://example.org/consently/consents", params: { categories: [], version: "1" }, as: :json

    assert_equal "example.org", Consently::ConsentRecord.sole.scope
  end
end
