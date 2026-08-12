# Demo configuration for the dummy app - fake ids on purpose, they are only
# here so you can watch the tags sit blocked and then come alive.
Consently.configure do |c|
  c.enabled = true
  c.policy_url = ->(view) { view.main_app.cookie_policy_path(locale: view.params[:locale]) }
  c.reload_after_choice = true
  c.log_consents = true

  c.tag :google_analytics, id: "G-DEMO12345"
  c.tag :clarity, id: "demoklarity"
  c.tag :meta_pixel, id: "1234567890"
  c.tag :plausible, domain: "example.com", category: :necessary
end
