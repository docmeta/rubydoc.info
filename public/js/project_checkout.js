function pollCheckout(project) {
  $.ajax({url: '/checkout/' + project, dataType: 'text'}).
    success(function(data) {
      if (data == "YES") {
        window.location = '/github/' + project;
      }
      else if (data == "ERROR") {
        checkoutError();
      } else {
        setTimeout("pollCheckout('" + project + "');", 2000);
      }
    }).
    error(checkoutError);
}

function checkoutError(data) {
  $('#rubydoc_checkout').removeClass('loading');
  $('#rubydoc_checkout').addClass('error');
  $('#rubydoc_submit')[0].disabled = false;
  return;
}

function checkoutForm() {
  $('#rubydoc_checkout_form').submit(function() {
    var url = $('#url')[0].value;
    var scheme = $('#scheme')[0].value;
    var commit = $('#commit')[0].value;
    $.post('/checkout', {scheme: scheme, url: url, commit: commit}, 'text').
      success(function(data) {
        if (data == "OK") {
          var arr = url.split('/');
          var dirname = arr[arr.length-1].replace(/\.[^.]+$/, '');
          var match = url.match(/^(?:git|https?):\/\/(?:www\.)?github\.com\/([^\/]+)/);
          if (match) {
            var name = match[1];
            dirname = name + '/' + dirname + '/' +
              (commit.length == 0 ? "master" : commit.length == 40 ? commit.substring(0,6) : commit);
          }
          pollCheckout(dirname);
        }
        else {
          checkoutError();
        }
      }).
      error(checkoutError);
    $('#rubydoc_submit')[0].disabled = true;
    $('#rubydoc_checkout').addClass('loading');
    return false;
  });
}

function advancedOptionsToggle() {
  $('#advanced_options').toggle(function() {
    $(this).text("Advanced options:");
    $('#rubydoc_checkout .extra_options').toggle();
  }, function () {
    $(this).text(">> Advanced options");
    $('#rubydoc_checkout .extra_options').toggle();
  });
}

$(checkoutForm);
$(advancedOptionsToggle);
