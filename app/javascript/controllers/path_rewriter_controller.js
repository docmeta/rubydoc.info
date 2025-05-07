import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    var re = new RegExp(
      "^" + window.location.protocol + "//" + window.location.host + "/"
    );
    if (document.referrer.match(re)) {
      localStorage.removeItem("defaultIndex");
      return;
    }

    const action = localStorage.getItem("defaultIndex");
    if (action) {
      Turbo.visit(`/${action}`, { action: "replace" });
    }
  }
}
