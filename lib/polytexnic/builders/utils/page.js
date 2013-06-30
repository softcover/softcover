var system = require('system');
var fs = require('fs');
var page = require('webpage').create();

console.log('Accessing page...')
page.open(system.args[1], function () {

    window.setTimeout(function () {
      console.log('Setting HTML...');
      var html = page.evaluate(function(){
        // var frames = document.getElementsByClassName("MathJax_SVG");
        var hiddenDiv = document.getElementById('MathJax_SVG_Hidden');
        var svgs = document.getElementsByTagName('svg');
        // var origDefs = svgs[0];
        var origDefs = hiddenDiv.nextSibling.firstChild;
        for (var i = 1; i < svgs.length; ++i)  {
          var defs = origDefs.cloneNode(false);
          var svg = svgs[i];
          var parent = svg.parent;
          // var frame = frames[i];
          // var svg = frame.children[0];
          // var svg = frame.getElementsByTagName('svg')[0];


          // append shallow defs and change xmlns.
          svg.insertBefore(defs, svg.firstChild);
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
          // n = i + 1;
          // // frame = document.getElementById('MathJax-Element-' + n + '-Frame');
          // var tmpDiv = document.createElement('div');
          // tmpDiv.appendChild(svg);
          // frame.appendChild(svg);
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