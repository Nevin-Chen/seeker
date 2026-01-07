import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.contentTarget.classList.add("hidden")
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-180")
    }
  }
}
