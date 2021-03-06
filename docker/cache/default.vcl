vcl 4.0;

import std;
import directors;

backend server {
  .host = "app";
  .port = "8080";
  .probe = { .url = "/"; .timeout = 1s; .interval = 5s; .window = 5; .threshold = 3; }
}

acl purge {
  "app";
  "localhost";
}

sub vcl_recv {
  set req.grace = 30s;

  // We don't need no cookies
  unset req.http.Cookie;

  if (req.url ~ "process=true") {
    return (pass); // don't cache process pages
  }

  if (req.url ~ "github\/Homebrew\/homebrew" || req.url ~ "github\/Homebrew\/legacy-homebrew") {
    return (synth(750, "https://rubydoc.info/github/Homebrew/brew"));
  }

  if (req.method == "PURGE") {
    if (!client.ip ~ purge) {
      return(synth(405, "Not allowed."));
    }
    return (purge);
  }

  set req.backend_hint = server;
}

sub vcl_synth {
  if (resp.status == 750) {
    set resp.http.Location = resp.reason;
    set resp.status = 301;
    return(deliver);
  }
}

sub vcl_backend_response {
  if (beresp.status != 200 || beresp.http.cache-control ~ "max-age=0") {
    set beresp.uncacheable = true;
    return (deliver); // no cache on non-200s
  } else {
    // one year cache
    set beresp.ttl = 365d;
    set beresp.do_esi = true;
  }
  return (deliver);
}

sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache-Status = "HIT";
  } else {
    set resp.http.X-Cache-Status = "MISS";
  }
}

sub vcl_backend_error {
  set beresp.ttl = 1s;
  set beresp.grace = 10s;

  if (beresp.status == 503) {
    return(retry);
  }

  set beresp.http.Content-Type = "text/html; charset=utf-8";
  synthetic({"
    <!DOCTYPE html>
      <html>
        <head><title>RubyDoc is having trouble</title></head>
        <body>
          <h1>RubyDoc is having trouble with this request</h1>
          <h3>Please visit <a href="https://rubydoc.tenderapp.com/">Help & Support</a> if this issue persists.</h3>
          <p>Error code: "} + beresp.status + {"</p>
        </body>
      </html>
    "});
    return (deliver);
}
