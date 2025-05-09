import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["focus"];

  connect() {
    const el = this.hasFocusTarget ? this.focusTarget : this.element;
    el.focus();
  }

  close(event) {
    if (
      (event.key === "Escape" && !event.target.value) ||
      event.target === this.element
    ) {
      this.element.remove();
    }
  }
}
