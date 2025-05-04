import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.setAttribute(
      "href",
      this.element.getAttribute("href").split("#")[1]
    );
  }
}
