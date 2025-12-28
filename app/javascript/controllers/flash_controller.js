import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 7000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
