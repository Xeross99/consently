import { Controller } from "@hotwired/stimulus"

// The banner, the preferences panel, and the part that actually matters:
// turning the blocked <script type="text/plain"> tags into live ones the
// moment the visitor agrees, so nobody has to reload to be counted.
export default class extends Controller {
  static targets = ["card", "preferences", "category", "settingsButton", "saveButton", "cancelButton"]

  // The panel slides open on a grid row, and things disappear by class rather
  // than by inline style. Both class names come from the markup, so restyling
  // the banner never means touching this file.
  static classes = ["open", "hidden"]

  static values = {
    cookie: { type: String, default: "consently" },
    version: { type: String, default: "1" },
    maxAge: { type: Number, default: 60 * 60 * 24 * 180 },
    path: { type: String, default: "/" },
    categories: Array,
    googleConsentMode: { type: Boolean, default: true },
    respectDoNotTrack: { type: Boolean, default: false },
    respectGpc: { type: Boolean, default: true },
    reload: { type: Boolean, default: false },
    // Whether the visitor had already chosen when the page was rendered, so
    // closing the panel knows whether to leave the banner behind or not.
    decided: { type: Boolean, default: false },
    logUrl: String,
    nonce: String
  }

  connect() {
    // An opt-out signal is an answer, so the banner never appears for it.
    if (this.#optedOut()) this.rejectAll()
  }

  acceptAll() {
    this.#store(this.categoriesValue)
  }

  rejectAll() {
    this.#store([])
  }

  // Anything anywhere on the page carrying data-consently-open reopens the
  // panel - a footer link is outside this controller's element, so it cannot
  // carry an action of its own.
  openFromLink(event) {
    if (!event.target.closest("[data-consently-open]")) return

    this.openPreferences(event)
  }

  openPreferences(event) {
    if (event) event.preventDefault()

    this.cardTarget.classList.remove(...this.hiddenClasses)
    this.preferencesTarget.classList.add(...this.openClasses)
    this.settingsButtonTarget.classList.add(...this.hiddenClasses)
    this.settingsButtonTarget.setAttribute("aria-expanded", "true")
    this.saveButtonTarget.classList.remove(...this.hiddenClasses)
    this.cancelButtonTarget.classList.remove(...this.hiddenClasses)

    // Someone who reopened this from a link in the footer is now looking at a
    // panel their screen reader has not been told about.
    this.cardTarget.focus({ preventScroll: true })
  }

  // Out of the panel without deciding anything: back to the short banner, or
  // out of the way entirely if the visitor had already chosen before.
  closePreferences() {
    this.#collapse()
    if (this.decidedValue) this.cardTarget.classList.add(...this.hiddenClasses)
  }

  savePreferences() {
    this.#store(this.categoryTargets.filter((box) => box.checked).map((box) => box.value))
  }

  // Consent is written, the page catches up, and the choice is logged - in
  // that order, so a failing log request cannot cost the visitor their click.
  #store(categories) {
    this.#writeCookie(categories)
    this.#activateScripts(categories)
    this.#updateGoogleConsent(categories)
    this.#logConsent(categories)

    this.#collapse()
    this.cardTarget.classList.add(...this.hiddenClasses)
    this.decidedValue = true

    this.dispatch("change", { detail: { categories }, target: document, prefix: "consently" })

    // Last, so anything listening for the event has already run.
    if (this.reloadValue) window.location.reload()
  }

  #collapse() {
    this.preferencesTarget.classList.remove(...this.openClasses)
    this.settingsButtonTarget.classList.remove(...this.hiddenClasses)
    this.settingsButtonTarget.setAttribute("aria-expanded", "false")
    this.saveButtonTarget.classList.add(...this.hiddenClasses)
    this.cancelButtonTarget.classList.add(...this.hiddenClasses)
  }

  #writeCookie(categories) {
    const value = JSON.stringify({ v: this.versionValue, c: categories, t: new Date().toISOString() })
    const secure = window.location.protocol === "https:" ? "; Secure" : ""

    document.cookie = `${this.cookieValue}=${encodeURIComponent(value)}; path=${this.pathValue}; max-age=${this.maxAgeValue}; SameSite=Lax${secure}`
  }

  #activateScripts(categories) {
    const granted = new Set([...categories, "necessary"])

    document.querySelectorAll('script[type="text/plain"][data-consently-category]').forEach((blocked) => {
      if (!granted.has(blocked.dataset.consentlyCategory)) return

      const script = document.createElement("script")
      // Copy everything the server put on the tag except our own bookkeeping,
      // so vendor attributes like data-domain survive.
      for (const { name, value } of blocked.attributes) {
        if (name === "type" || name.startsWith("data-consently-")) continue
        script.setAttribute(name, value)
      }
      script.dataset.consentlyCategory = blocked.dataset.consentlyCategory

      if (this.nonceValue) script.setAttribute("nonce", this.nonceValue)
      if (blocked.dataset.consentlySrc) {
        script.src = blocked.dataset.consentlySrc
      } else {
        script.textContent = blocked.textContent
      }
      if (blocked.dataset.consentlyAsync) script.async = true
      if (blocked.dataset.consentlyDefer) script.defer = true

      blocked.replaceWith(script)
    })
  }

  // Google's consent mode v2: the page loaded with everything denied, this
  // lifts exactly what was granted.
  #updateGoogleConsent(categories) {
    if (!this.googleConsentModeValue) return

    const analytics = categories.includes("analytics") ? "granted" : "denied"
    const marketing = categories.includes("marketing") ? "granted" : "denied"

    window.dataLayer = window.dataLayer || []
    // gtag pushes its `arguments` object, not an array - Google's tags read it
    // by position and an array is not the same thing to them.
    const gtag = function () { window.dataLayer.push(arguments) }
    gtag("consent", "update", {
      analytics_storage: analytics,
      ad_storage: marketing,
      ad_user_data: marketing,
      ad_personalization: marketing
    })
    window.dataLayer.push({ event: "consently_consent_update", consently_categories: categories.join(",") })
  }

  async #logConsent(categories) {
    if (!this.logUrlValue) return

    try {
      await fetch(this.logUrlValue, {
        method: "POST",
        // The page may be reloading a moment later; keepalive means the
        // request still reaches us instead of being cancelled.
        keepalive: true,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content ?? ""
        },
        body: JSON.stringify({ categories, version: this.versionValue })
      })
    } catch (error) {
      // A lost log entry is not worth breaking the page over.
      console.warn("[consently] could not record consent", error)
    }
  }

  // Global Privacy Control is a binding opt-out signal in California and
  // Colorado; Do Not Track is advisory, which is why that one is opt-in.
  #optedOut() {
    if (this.respectGpcValue && navigator.globalPrivacyControl === true) return true

    return this.respectDoNotTrackValue &&
      [navigator.doNotTrack, window.doNotTrack, navigator.msDoNotTrack].includes("1")
  }
}
