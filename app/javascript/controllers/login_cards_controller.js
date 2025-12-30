import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  highlight(event) {
    event.currentTarget.style.transform = "translateY(-6px)"
    event.currentTarget.style.boxShadow = "0 10px 25px rgba(78, 0, 33, 0.9)"
  }

  reset(event) {
    event.currentTarget.style.transform = ""
    event.currentTarget.style.boxShadow = ""
  }
}
