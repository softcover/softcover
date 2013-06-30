var system = require('system');
var fs = require('fs');
var page = require('webpage').create();

console.log('Accessing page...')
page.open(system.args[1], function () {

    window.setTimeout(function () {
      console.log('Setting HTML...');
      var html = page.evaluate(function(){
        frames = document.getElementsByClassName("MathJax_SVG");
        console.log(document.getElementById('MathJax_SVG_Hidden'))
        var hiddenDiv = document.getElementById('MathJax_SVG_Hidden')
        var origDefs = hiddenDiv.nextSibling.childNodes[0];
        for (var i = 0; i < frames.length; ++i)  {
          var defs = origDefs.cloneNode(false);
          var frame = frames[i];
          var svg = frame.children[0];

          // append shalow defs and change xmlns.
          svg.insertBefore(defs, svg.childNodes[0]);
          svg.setAttribute("xmlns", "http://www.w3.org/2000/svg");

          // clone and copy all used paths into local defs.
          // xlink:href in uses FIX
          var uses = svg.getElementsByTagName("use");
          for (var k = 0; k < uses.length; ++k) {
            var id = uses[k].getAttribute("href");
            defs.appendChild(
              document.getElementById(id.substr(1)).cloneNode(true)
            );
            uses[k].setAttribute("xlink:href", id);
          }
          svg.style.position = "static";
          n = i + 1;
          // frame = document.getElementById('MathJax-Element-' + n + '-Frame');
          var tmpDiv = document.createElement('div');
          tmpDiv.appendChild(svg);
          frame.appendChild(svg);
          // frame.innerHTML = "<em>foo" + n + "</em>"; // tmpDiv.innerHTML;
        }
        svg_crud = document.getElementsByTagName('div')[0];
        svg_crud.parentNode.removeChild(svg_crud);
        return document.body.innerHTML;
      });

      utf8 = '<meta http-equiv="Content-type" content="text/html; charset=utf-8">'
      fs.write('phantomjs_source.html', utf8 + html, 'w');
      phantom.exit();
    }, 600);
});