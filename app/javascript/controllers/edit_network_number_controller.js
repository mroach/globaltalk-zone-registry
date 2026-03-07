import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["number", "freeNumber"]

  use() {
    this.numberTarget.value = this.freeNumberTarget.innerText;
  }
}
