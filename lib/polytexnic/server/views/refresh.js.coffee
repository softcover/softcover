wait = ->
  $.getJSON(window.location.pathname + '/wait', ->
    $.get window.location.pathname + '.js', (html)->
      $('#book').html html
      initMathJax()
      wait()
  ).fail -> wait()

initMathJax = ->
  $('#mathJaxJS').remove()
  delete MathJax

  script = document.createElement( 'script' )
  script.id = 'mathJaxJS'
  script.type = 'text/javascript'
  script.src = 'http://cdn.mathjax.org/mathjax/latest/MathJax.js' +
               '?config=TeX-AMS_HTML'
  script.innerHTML = '
      MathJax.Hub.Config({
        "HTML-CSS": {
          availableFonts: ["TeX"],
        },
        showProcessingMessages: false,
        messageStyle: "none"
      });
    '

  $('head').append script

$ ->
  initMathJax()
  wait()
