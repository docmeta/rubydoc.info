function createGithubLinks() {
  if (!window.location.pathname.startsWith("/github/")) return;

  document.querySelectorAll(".showSource").forEach(function (element) {
    var nextElement = element.nextElementSibling;
    if (!nextElement) return;

    var fileInfo = nextElement.querySelector(".info.file");
    if (!fileInfo) return;

    var match = fileInfo.textContent.match(/^# File '([^']+)', line (\d+)/);
    if (!match) return;

    var file = match[1];
    var line = match[2];
    var url =
      "https://github.com/" +
      window.yard_library_name +
      "/blob/" +
      window.yard_library_version +
      "/" +
      file +
      "#L" +
      line;

    var container = document.createElement("span");
    container.style.fontSize = "0.9em";
    container.appendChild(document.createTextNode(" ["));

    var link = document.createElement("a");
    link.target = "_new";
    link.href = url;
    link.textContent = "View on GitHub";
    container.appendChild(link);
    container.appendChild(document.createTextNode("]"));

    element.insertAdjacentElement("afterend", container);
  });
}

document.addEventListener("DOMContentLoaded", createGithubLinks);
