# Changelog

## 1.0.0 (2026-09-04)

- Events speak the language of the page's tags: `gtag('event', ...)` under
  gtag.js, a `dataLayer` push under Google Tag Manager, decided per request
  from the tags in scope or forced with `event_transport`. Before, every event
  was a dataLayer push - which gtag.js ignores, so a shop without a container
  lost its whole ecommerce funnel.
- An event rendered without consent is held back as an inert script and
  released with the tags when its category is granted, instead of being
  dropped. The page a visitor accepts on now counts its `view_item`.
- `consently_stream_event` sends an event from a Turbo Stream response - the
  add-to-cart that never renders a page - through a stream action that ships
  with the banner controller; it is sent at once with consent and queued
  until then otherwise.
- `Consently.track(event, payload, { category })` and `Consently.granted()`
  in JavaScript, on the same queue.
- `consently_event` is the new name of `consently_data_layer_push`; the old
  one still works.

## 0.2.1 (2026-08-13)

- The banner's custom properties moved from `.consently` to `:root`, so the
  button on a blocked embed - which lives elsewhere on the page and wears the
  same classes - is styled like the one in the banner instead of losing its
  background. Overriding them on `.consently` still themes the banner.
- The cookie policy pluralises durations, so a one-day cookie no longer reads
  "1 days"; the Slavic locales carry the full set of forms.
- A page anybody can open: <https://xeross99.github.io/consently/> runs four
  tags blocked in the browser, and shows what happens to them - and to the
  requests, the cookies and the dataLayer - the moment consent is given.

## 0.2.0 (2026-08-13)

- `consently_embed` for videos and maps: a YouTube or Vimeo iframe, or a
  Google map, waits behind a placeholder until its category is granted and
  then appears without a reload.
- `consently_ecommerce` builds GA4 ecommerce events from your own line items
  or products, clearing the previous `ecommerce` object the way Google asks.
- `google_consent_mode` now takes `:basic` (the previous behaviour) or
  `:advanced`, which lets Google's own tags load denied so Ads can model the
  conversions of visitors who refused.
- `cookie_domain`, so one consent covers every subdomain.
- `consent_max_age`, to ask again after a year without bumping the policy
  version.

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
