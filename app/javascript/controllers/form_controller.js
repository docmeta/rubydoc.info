import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.previousValue = this.element.value;
  }

  start() {
    this.element.disabled = true;
    this.element.value = this.element.dataset.disableWith;
  }

  end() {
    this.element.disabled = false;
    this.element.value = this.previousValue;
    this.element.dispatchEvent(new Event("change"));
  }
}
