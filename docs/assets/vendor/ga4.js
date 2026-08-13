// A stand-in for https://www.googletagmanager.com/gtag/js on this site's own
// domain, so the demo can prove a point without sending anybody to Google:
// this file is only ever fetched after the visitor agrees.
(function () {
  document.cookie = "_ga=GA1.1.DEMO." + Date.now() + "; path=/; max-age=3600; SameSite=Lax"
  document.cookie = "_gid=GA1.1.DEMO; path=/; max-age=3600; SameSite=Lax"

  window.__consentlyDemo.vendorLoaded("Google Analytics 4", ["_ga", "_gid"])
})()
