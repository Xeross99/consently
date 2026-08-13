// Stands in for https://connect.facebook.net/en_US/fbevents.js — marketing, so
// it waits for a category most visitors will leave switched off.
(function () {
  document.cookie = "_fbp=fb.1.DEMO." + Date.now() + "; path=/; max-age=3600; SameSite=Lax"

  window.__consentlyDemo.vendorLoaded("Meta Pixel", ["_fbp"])
})()
