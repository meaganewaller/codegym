import { Controller } from "@hotwired/stimulus"

// A timer that survives a reload and does not drift.
//
// Elapsed time is derived from a start timestamp rather than counted by interval
// ticks: browsers throttle timers in background tabs, so a counter that adds a
// second per tick loses time whenever the tab is not visible. The interval here
// only decides how often the display is redrawn.
//
// State lives in localStorage under the exercise slug, so two exercises keep
// separate timers and a reload picks the running one back up.
const PHASES = {
  plan: { label: "Plan", announcement: "Plan phase. Write down your approach." },
  build: { label: "Build", announcement: "Build phase. Start writing code." },
  reflect: { label: "Reflect", announcement: "Reflect phase. Wrap up and note what you learned." }
}

const BLANK = { startedAt: null, accumulated: 0, running: false }

export default class extends Controller {
  static targets = ["clock", "phase", "announcer", "toggle"]
  static values = { slug: String, minutes: Number }

  connect() {
    this.state = this.read()

    // Seed the phase without announcing it. A reload should not shout the
    // current phase at someone who never changed it.
    this.phase = this.phaseFor(this.elapsed())
    this.paint({ announce: false })

    this.ticker = setInterval(() => this.paint(), 1000)
  }

  disconnect() {
    clearInterval(this.ticker)
  }

  toggle() {
    if (this.state.running) {
      this.state = { startedAt: null, accumulated: this.elapsed(), running: false }
    } else {
      this.state = { ...this.state, startedAt: Date.now(), running: true }
    }

    this.write()
    this.paint()
  }

  reset() {
    this.state = { ...BLANK }
    this.phase = this.phaseFor(0)
    this.write()
    this.paint({ announce: false })
  }

  // --- time -----------------------------------------------------------------

  elapsed() {
    const running = this.state.running && this.state.startedAt
    const since = running ? Date.now() - this.state.startedAt : 0

    // Math.max guards a clock that moved backwards, which would otherwise show
    // the timer running in reverse.
    return this.state.accumulated + Math.max(0, since)
  }

  phaseFor(elapsed) {
    const total = this.minutesValue * 60_000
    if (!(total > 0)) return "build"

    const fraction = elapsed / total
    if (fraction < 1 / 6) return "plan"
    if (fraction < 5 / 6) return "build"
    return "reflect"
  }

  format(elapsed) {
    const seconds = Math.floor(elapsed / 1000)
    const minutes = Math.floor(seconds / 60)
    return `${String(minutes).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`
  }

  // --- rendering ------------------------------------------------------------

  paint({ announce = true } = {}) {
    const elapsed = this.elapsed()

    this.clockTarget.textContent = this.format(elapsed)
    this.toggleTarget.textContent = this.state.running ? "Pause" : elapsed > 0 ? "Resume" : "Start"

    const phase = this.phaseFor(elapsed)
    if (phase !== this.phase || !announce) {
      this.phase = phase
      this.phaseTarget.textContent = PHASES[phase].label
      this.element.dataset.phase = phase

      // Only a real change reaches the live region.
      if (announce) this.announcerTarget.textContent = PHASES[phase].announcement
    }
  }

  // --- storage --------------------------------------------------------------

  get storageKey() {
    return `codegym.timer.${this.slugValue}`
  }

  read() {
    try {
      const raw = window.localStorage.getItem(this.storageKey)
      if (!raw) return { ...BLANK }

      const saved = JSON.parse(raw)
      return {
        startedAt: Number.isFinite(saved.startedAt) ? saved.startedAt : null,
        accumulated: Number.isFinite(saved.accumulated) ? Math.max(0, saved.accumulated) : 0,
        running: Boolean(saved.running)
      }
    } catch {
      // Private browsing, disabled storage, or a value someone hand-edited.
      // A timer that starts from zero beats a page that will not load.
      return { ...BLANK }
    }
  }

  write() {
    try {
      window.localStorage.setItem(this.storageKey, JSON.stringify(this.state))
    } catch {
      // Nothing to do: the timer still works for this page view.
    }
  }
}
