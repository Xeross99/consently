// Analytics events that wait for consent.
//
// Three roads lead here. An event rendered into a page without consent is an
// inert <script> the banner releases together with the tags - nothing to do
// on this side. A <turbo-stream action="consently_event"> comes from a
// response that renders no page, and window.Consently.track() from your own
// code; those two are sent at once when their category is granted and kept
// until it is otherwise, so an add-to-cart that happened before the click is
// counted after it.
//
// The page says what is granted and how to send in two <meta> tags written by
// consently_tags. The banner's consently:change event overrides the first the
// moment a choice is made, and the next Turbo visit brings a fresh page whose
// tags already know.

const NECESSARY = "necessary"
const waiting = []
let decided = null

export function track(name, payload = {}, { category = "analytics", ecommerce = false } = {}) {
  const event = { name, payload, category, ecommerce }

  if (granted(category)) send(event)
  else waiting.push(event)
}

export function granted(category) {
  if (category === NECESSARY) return true

  return (decided ?? meta("consently-granted").split(" ")).includes(category)
}

function meta(name) {
  return document.querySelector(`meta[name="${name}"]`)?.content ?? ""
}

function send({ name, payload, ecommerce }) {
  window.dataLayer = window.dataLayer || []

  if (meta("consently-transport") === "gtag") {
    // gtag.js reads the queue, so this is safe before the tag has loaded.
    window.gtag = window.gtag || function () { window.dataLayer.push(arguments) }
    window.gtag("event", name, payload)
  } else if (ecommerce) {
    window.dataLayer.push({ ecommerce: null })
    window.dataLayer.push({ event: name, ecommerce: payload })
  } else {
    window.dataLayer.push({ event: name, ...payload })
  }
}

function release(categories) {
  decided = [...categories, NECESSARY]

  waiting.splice(0).forEach((event) => (granted(event.category) ? send(event) : waiting.push(event)))
}

document.addEventListener("consently:change", (event) => release(event.detail.categories))

// A new page carries the server's reading of the cookie, which also knows
// about policy versions and expiry; from here on it is the one to trust.
document.addEventListener("turbo:load", () => { decided = null })

// The Turbo Stream action. A listener rather than an entry in
// Turbo.StreamActions, so the gem imports nothing from Turbo and the order
// the modules load in does not matter.
document.addEventListener("turbo:before-stream-render", (event) => {
  const stream = event.target
  if (stream.getAttribute("action") !== "consently_event") return

  event.preventDefault()
  track(stream.getAttribute("event"), JSON.parse(stream.getAttribute("payload") || "{}"), {
    category: stream.getAttribute("category") || "analytics",
    ecommerce: stream.getAttribute("ecommerce") === "true"
  })
})

window.Consently = Object.assign(window.Consently || {}, { track, granted })
