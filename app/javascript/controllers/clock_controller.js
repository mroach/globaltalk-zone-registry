import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["face"];

  static values = {
    tz: String
  }

  connect() {

    if ('Temporal' in window) {
      const tz = this.tzValue;
      this.#startClock(this.faceTarget, tz);
    }
  }

  #startClock(element, timeZone) {
    function tick() {
      const now = Temporal.Now.zonedDateTimeISO(timeZone)

      const day = now.toLocaleString('en', { weekday: 'short' })
      const time = now.toPlainTime().toString({ smallestUnit: 'second' })
      element.textContent = `${day} ${time}`

      // schedule next tick exactly on the next second boundary
      const msUntilNextSecond = 1000 - now.epochMilliseconds % 1000
      setTimeout(tick, msUntilNextSecond)
    }

    tick()
  }
}
