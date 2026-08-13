// Stands in for https://www.clarity.ms/tag/… — a local file, fetched only once
// analytics consent exists.
(function () {
  document.cookie = "_clck=demo/1/consently; path=/; max-age=3600; SameSite=Lax"
  document.cookie = "_clsk=demo; path=/; max-age=3600; SameSite=Lax"

  window.__consentlyDemo.vendorLoaded("Microsoft Clarity", ["_clck", "_clsk"])
})()
