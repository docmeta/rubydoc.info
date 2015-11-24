function createGithubLinks() {
  if (match = window.location.pathname.match(/^\/github\/([^\/]+\/[^/]+)\/(?:[^/]+)/)) {
    var github_project = match[1];
    var github_commit = $('#menu .title small').text().replace(/^\(|\)\s*$/g, '');

    $(".source_code").each( function() {
       if (match = $(this).find(".info.file").text().match(/^# File '([^']+)', line (\d+)/)) {
          var file = match[1];
          var line = match[2];

          var url = "https://github.com/" + github_project +
                    "/blob/" + github_commit + "/" +
                    file +
                    "#L" + line;

          $(this).before(' [<a target="_new" href="' + url + '">View on GitHub</a>]');
        }
    });
  }
}

$(createGithubLinks);
