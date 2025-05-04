function createGithubLinks() {
  if (window.location.pathname.indexOf("/github/") !== 0) return;

  $(".showSource").each(function () {
    if (
      (match = $(this)
        .next()
        .find(".info.file")
        .text()
        .match(/^# File '([^']+)', line (\d+)/))
    ) {
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

      $(this).after(
        ' <span style="font-size: 0.9em">[<a target="_new" href="' +
          url +
          '">View on GitHub</a>]</span>'
      );
    }
  });
}

$(createGithubLinks);
