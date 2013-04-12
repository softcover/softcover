require 'maruku'
require 'fileutils'

module Polytexnic
  module Builders
    class Html < Builder
      def setup
        Dir.mkdir "html" unless File.directory?("html")
        unless File.directory?(File.join("html", "stylesheets"))
          Dir.mkdir File.join("html", "stylesheets")
        end
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
          polytex = File.read(polytex_filename)
          includes = polytex.scan(/(\\include{(.*?)})/)
          includes.each do |command, filename|
            content = File.open(filename + '.tex') { |f| f.read }
            wrapped = %{
              \\begin{xmlelement}{chapterWr}
                #{content}
              \\end{xmlelement}
            }
            polytex.gsub!(command, wrapped)
          end
          html_body = Polytexnic::Core::Pipeline.new(polytex).to_html
          html_filename = File.join('html', basename + '.html')
          file_content = template(html_body)
          File.open(html_filename, 'w') do |f|
            f.write(file_content)
          end
          write_pygments_file(:html, File.join('html', 'stylesheets'))
          @built_files.push html_filename

          # build html fragments
          # TODO: run original html through nokogiri to preserve x-refs
          xml = Nokogiri::HTML(file_content)
          xml.css('.chapterWr').each_with_index do |node,i|
            chapter = @manifest.chapters[i]

            html_filename = File.join('html', chapter.slug + '_fragment.html')
            File.open(html_filename, 'w') do |f|
              f.write(node)
            end

            @built_files.push html_filename
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
<link href="stylesheets/pygments.css" media="screen" rel="stylesheet" type="text/css" />
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
</html>
  EOS
end
