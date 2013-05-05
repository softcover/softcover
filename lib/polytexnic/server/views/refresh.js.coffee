wait = ->
  $.getJSON window.location.pathname + '/wait', ->
    $.get window.location.pathname + '.js', (html)->
      $('#book').html html
      wait()

$ -> wait()



