function checkoutError(data) {
  $("#checkout").removeClass("loading");
  $("#checkout").addClass("error");
  $("#submit")[0].disabled = false;
  return;
}

function checkoutForm() {
  $("#checkout_form").submit(function () {
    var url = $("#url")[0].value;
    var scheme = $("#scheme")[0].value;
    var commit = $("#commit")[0].value;
    $.ajax({
      type: "POST",
      url: "/checkout",
      data: { scheme: scheme, url: url, commit: commit },
      dataType: "json",
    })
      .success(function (data) {
        if (data.status === "OK") {
          if (window.location.pathname === data.project_path) {
            window.location.reload();
          } else {
            window.location = data.project_path;
          }
        } else {
          checkoutError();
        }
      })
      .error(checkoutError);
    $("#submit")[0].disabled = true;
    $("#checkout").addClass("loading");
    return false;
  });
}

function advancedOptionsToggle() {
  $("#advanced_options").toggle(
    function () {
      $(this).text("Advanced options:");
      $("#checkout .extra_options").toggle();
    },
    function () {
      $(this).text(">> Advanced options");
      $("#checkout .extra_options").toggle();
    }
  );
}

$(checkoutForm);
$(advancedOptionsToggle);
