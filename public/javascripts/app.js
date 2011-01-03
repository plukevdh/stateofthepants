$(document).ready(function() {

  $(".eval").click(function(e) {
    e.preventDefault()
    $.post($(this).attr("href"))

    $("#evals").html("<h2>Thanks for helping us improve!</h2>")
  })

})
