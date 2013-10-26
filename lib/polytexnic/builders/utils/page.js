// Processes an HTML page, including any MathJax math typesetting.
// Output is written to the file `phantomjs_source.html`.

var system = require('system');
var fs = require('fs');
var page = require('webpage').create();

page.open(system.args[1], function (status) {
    if (status !== "success") {
      console.log("Unable to access network");
    } else {
      //
      //  This gets called when MathJax is done
      //
      page.onAlert = function (msg) {
        if (msg === "MathJax Done") {
          var html = page.evaluate(function(){
            var hiddenDiv = document.getElementById('MathJax_SVG_Hidden');
            var svgs = document.getElementsByTagName('svg');
            var origDefs = hiddenDiv.nextSibling.firstChild;
            for (var i = 1; i < svgs.length; ++i)  {
              var defs = origDefs.cloneNode(false);
              var svg = svgs[i];
              // append shallow defs and change xmlns.
              svg.insertBefore(defs, svg.firstChild);
              svg.setAttribute("xmlns", "http://www.w3.org/2000/svg");
              // clone and copy all used paths into local defs.
              var uses = svg.getElementsByTagName("use");
              for (var k = 0; k < uses.length; ++k) {
                var id = uses[k].getAttribute("href");
                defs.appendChild(
                  document.getElementById(id.substr(1)).cloneNode(true)
                );
                uses[k].setAttribute("xlink:href", id);
              }
              svg.style.position = "static";
            }
            svg_defs = document.getElementsByTagName('div')[0];
            svg_defs.parentNode.removeChild(svg_defs);
            return document.body.innerHTML;
          });

          utf8 = '<meta http-equiv="Content-type" content="text/html; charset=utf-8">'
          fs.write('phantomjs_source.html', utf8 + html, 'w');
          phantom.exit();
        } else if (msg === "MathJax Timeout") {
            console.log("Timed out waiting for MathJax");
            phantom.exit();
        } else { console.log(msg) }
      }
    }

    page.evaluate(function () {
      var script = document.createElement("script");
      script.type = "text/x-mathjax-config";
      script.text = "MathJax.Hub.Queue([alert,'MathJax Done'])";
      document.head.appendChild(script);
      // Time out after 60 seconds, which should be long enough for
      // almost all documents.
      setTimeout(function () { alert("MathJax Timeout") }, 60000);
    });
});