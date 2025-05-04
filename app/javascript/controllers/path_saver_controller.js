import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    localStorage.setItem("defaultIndex", this.element.dataset.path);
  }
}
