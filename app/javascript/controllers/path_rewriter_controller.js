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

    Turbo.visit(localStorage.getItem("defaultIndex"), { action: "replace" });
  }
}
