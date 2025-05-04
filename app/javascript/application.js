import "@hotwired/turbo-rails";
import "controllers";

function helpLink() {
  const helpElement = document.getElementById("help");
  if (!helpElement) return;

  helpElement.addEventListener("click", function () {
    const tenderWindow = document.getElementById("tender_window");
    const helpTender = document.getElementById("help_tender");
    const infoElement = document.getElementById("info");
    const checkoutElement = document.getElementById("checkout");

    if (
      tenderWindow &&
      window.getComputedStyle(tenderWindow).display !== "none"
    ) {
      tenderWindow.style.display = "none";
    } else {
      // Simulate click on help_tender link
      if (helpTender) {
        const clickEvent = new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          view: window,
        });
        helpTender.dispatchEvent(clickEvent);
      }
      infoElement.style.display = "none";
      checkoutElement.style.display = "none";
    }
  });
}

// Replace jQuery document ready with modern approach
document.addEventListener("DOMContentLoaded", function () {
  helpLink();
});
