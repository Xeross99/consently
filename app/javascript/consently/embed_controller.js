import { Controller } from "@hotwired/stimulus"

// A video or map that appears the moment its category is granted. The banner
// announces every decision on `document`, so this controller only has to
// listen and build the iframe the server did not render.
export default class extends Controller {
  static targets = ["placeholder"]
  static classes = ["hidden"]

  static values = {
    category: String,
    src: String,
    title: String,
    attributes: { type: Object, default: {} }
  }

  // The event carries the categories, so no cookie parsing here.
  granted({ detail }) {
    if (!detail.categories.includes(this.categoryValue)) return

    this.#insertFrame()
  }

  #insertFrame() {
    if (this.element.querySelector("iframe")) return

    const frame = document.createElement("iframe")
    frame.src = this.srcValue
    frame.title = this.titleValue
    frame.loading = "lazy"
    frame.allowFullscreen = true
    frame.className = "consently-embed__frame"
    for (const [name, value] of Object.entries(this.attributesValue)) {
      frame.setAttribute(name, value)
    }

    this.element.prepend(frame)
    this.placeholderTarget.classList.add(...this.hiddenClasses)
  }
}
