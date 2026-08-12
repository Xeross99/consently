# Changelog

## 0.1.0 (2026-08-12)

First release.

- Tag registry: Google Tag Manager, GA4, Google Ads, Microsoft Clarity, Meta
  Pixel, Hotjar, Plausible, and `:custom` for anything else.
- Non-essential tags render as inert `<script type="text/plain">` whose source
  the browser never fetches, and become live scripts on consent without a
  reload.
- Google Consent Mode v2: denied by default before any Google tag, updated the
  moment the visitor chooses.
- Banner and preferences panel in plain CSS - no Tailwind, no build step -
  themed through custom properties, driven by one Stimulus controller, and
  translated into ten languages.
- `consently_policy` generates the cookie policy from the same configuration:
  categories, vendors, the cookies each one sets and how long they last.
- Per-domain or per-tenant tag sets from a single initializer.
- Optional consent log in your own database, anonymous unless you name the
  subject yourself.
- Global Privacy Control honoured by default, Do Not Track opt-in, and
  `consent_required` for deciding who has to be asked at all.
