function pollCheckout(project) {
  $.ajax({ 
    url: '/checkout/' + project, 
    success: function(data) {
      if (data == "YES") {
        window.location = '/github/' + project + '/frames';
      }
      else if (data == "ERROR") {
        $('#checkout').removeClass('loading');
        $('#checkout').addClass('error');
        $('#submit')[0].disabled = false;
        return;
      } else {
        setTimeout("pollCheckout('" + project + "');", 2000);
      }
    }, 
    error: function(data) {
      $('#checkout').removeClass('loading');
      $('#checkout').addClass('error');
      $('#submit')[0].disabled = false;
      return;
    },
    dataType: 'text' 
  });
}

function checkoutForm() {
  $('#checkout_form').submit(function() {
    var url = $('#url')[0].value;
    var scheme = $('#scheme')[0].value;
    var commit = $('#commit')[0].value;
    $.post('/checkout', {scheme: scheme, url: url, commit: commit}, function(data) {
      if (data == "OK") {
        var arr = url.split('/');
        var dirname = arr[arr.length-1].replace(/\.[^.]+$/, '');
        var match = url.match(/^(?:git|https?):\/\/(?:www\.)?github\.com\/([^\/]+)/);
        if (match) {
          var name = match[1];
          dirname = name + '/' + dirname + '/' + (commit.length == 0 ? "master" : commit.length == 40 ? commit.substring(0,6) : commit);
        }
        pollCheckout(dirname);
      }
      else {
        $('#checkout').removeClass('loading');
        $('#checkout').addClass('error');
        $('#submit')[0].disabled = false;
      }
    }, 'text');
    $('#submit')[0].disabled = true;
    $('#checkout').addClass('loading');
    return false;
  });
}

function advancedOptionsToggle() {
  $('#advanced_options').toggle(function() {
    $(this).text("Advanced options:");
    $('#checkout .extra_options').toggle();
  }, function () {
    $(this).text(">> Advanced options");
    $('#checkout .extra_options').toggle();
  });
}

$(checkoutForm);
$(advancedOptionsToggle);
