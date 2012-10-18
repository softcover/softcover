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
          raise "Non-markdown building not implemented"
        end

        true
      end

      def clean!
        FileUtils.rm_rf "html"
      end
    end
  end
end