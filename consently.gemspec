require_relative "lib/consently/version"

Gem::Specification.new do |spec|
  spec.name        = "consently"
  spec.version     = Consently::VERSION
  spec.authors     = [ "Michał Krzysteczko" ]
  spec.email       = [ "m.krzysteczko@icloud.com" ]
  spec.homepage    = "https://github.com/Xeross99/consently"
  spec.summary     = "GDPR cookie consent for Rails that actually blocks your analytics tags until the visitor agrees"
  spec.description = <<~TEXT.gsub(/\s+/, " ").strip
    Most Rails cookie banners ask for consent and then load Google Analytics
    anyway. Consently is the other half: declare your tags once - GA4, Google
    Tag Manager, Google Ads, Microsoft Clarity, Meta Pixel, Hotjar, Plausible
    or anything custom - and it renders every non-essential one as an inert
    script the browser will not even fetch, then turns them into live scripts
    the instant the visitor agrees, with no page reload. Google Consent Mode
    v2 defaults are emitted before any Google tag and updated on the click.
    The banner and its preferences panel ship translated into ten European
    languages, styled in plain CSS with no Tailwind and no build step, and
    driven by one Stimulus controller. Your cookie policy page is generated
    from the same configuration - every vendor, every cookie it sets and for
    how long - so it cannot drift out of date. Multi-tenant applications get
    per-domain or per-shop tag sets from a single initializer, and an optional
    consent log stores proof of each decision in your own database, with no
    third-party service and nothing leaving your infrastructure.
  TEXT
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
end
