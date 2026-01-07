import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "header"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.backdropTarget.classList.toggle("hidden")

    this.headerTarget.classList.toggle("bg-white")
    this.headerTarget.classList.toggle("shadow-sm")

    if (!this.panelTarget.classList.contains("hidden")) {
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = ""
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
    this.headerTarget.classList.remove("bg-white", "shadow-sm")
    document.body.style.overflow = ""
  }
}
