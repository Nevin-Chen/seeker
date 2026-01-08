import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input", "error"]

  connect() {
    if (this.hasErrorTarget) {
      this.formTarget.classList.remove("hidden")
      this.displayTarget.classList.add("hidden")
    }
  }

  edit(event) {
    event.preventDefault()
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel(event) {
    event.preventDefault()

    const originalValue = this.inputTarget.dataset.originalValue
    this.inputTarget.value = originalValue

    if (this.hasErrorTarget) {
      this.errorTarget.remove()
    }

    this.inputTarget.classList.remove('border-red-500')
    this.inputTarget.classList.add('border-gray-300')

    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.cancel(event)
    }
  }
}
