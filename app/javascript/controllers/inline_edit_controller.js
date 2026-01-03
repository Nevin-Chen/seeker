import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input", "updateButton", "cancelButton"]

  edit(event) {
    event.preventDefault()
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel(event) {
    event.preventDefault()
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")

    this.inputTarget.value = this.inputTarget.dataset.originalValue
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.cancel(event)
    }
  }
}
