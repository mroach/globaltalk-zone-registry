import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker"];

  connect() {
    if ('Temporal' in window) {
      const userTz = Temporal.Now.timeZoneId();
      // obviously this shouldn't be hardcoded, but it works
      if (this.pickerTarget.value == 'Etc/UTC') {
        this.pickerTarget.value = userTz;
      }
    }
  }
}
