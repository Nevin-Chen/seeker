import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.outsideClickListener = this.handleOutsideClick.bind(this)
  }

  toggle(event) {
    event.stopPropagation()

    const isOpen = !this.menuTarget.classList.contains("opacity-0")

    if (isOpen) {
      this.close()
    } else {
      this.open()
      document.addEventListener("click", this.outsideClickListener)
    }
  }

  open() {
    this.menuTarget.classList.remove(
      "opacity-0",
      "scale-95",
      "pointer-events-none"
    )
  }

  close() {
    this.menuTarget.classList.add(
      "opacity-0",
      "scale-95",
      "pointer-events-none"
    )

    document.removeEventListener("click", this.outsideClickListener)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
