require 'maruku'
require 'fileutils'

module Polytexnic
  module Builders
    class Html < Builder
      def setup
        Dir.mkdir "html" unless File.directory?("html")
      end

      def build
        if @manifest.md?
          @manifest.chapters.each do |chapter|
            path = chapter.slug
            
            md = Maruku.new File.read(path)

            basename = File.basename path, ".*"

            fragment_path = "html/#{basename}_fragment.html"
            f = File.open fragment_path, "w"
            f.write md.to_html
            f.close

            doc_path = "html/#{basename}.html"
            f = File.open doc_path, "w"
            f.write md.to_html_document
            f.close

            @built_files.push fragment_path, doc_path
          end
        else
          basename = File.basename(@manifest.filename, '.tex')
          polytex_filename = basename + '.tex'
          polytex = File.open(polytex_filename) { |f| f.read }
          includes = polytex.scan(/(\\include{(.*?)})/)
          includes.each do |command, filename|
            content = File.open(filename + '.tex') { |f| f.read }
            polytex.gsub!(command, content)
          end
          html_body = Polytexnic::Core::Pipeline.new(polytex).to_html
          html_filename = File.join('html', basename + '.html')
          File.open(html_filename, 'w') do |f|
            f.write(template(html_body))
          end
        end

        true
      end

      def clean!
        FileUtils.rm_rf "html"
      end
    end
  end
end

# TODO: Replace this with a file.
def template(body)
<<-EOS
<!DOCTYPE html>
<head>
<meta charset="UTF-8">
<style>
.tt { font-family: Courier; font-size: 90%; }
</style>
<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML">
  MathJax.Hub.Config({
    "HTML-CSS": {
      availableFonts: ["TeX"]
    }
  });
</script>
</head>
<body>
#{body}
</body>
EOS
end