// Stands in for https://www.googletagmanager.com/gtm.js — same story as ga4.js:
// nothing is fetched from here until a category is granted.
(function () {
  window.dataLayer = window.dataLayer || []
  window.dataLayer.push({ event: "gtm.js", "gtm.start": Date.now() })

  window.__consentlyDemo.vendorLoaded("Google Tag Manager", [])
})()
