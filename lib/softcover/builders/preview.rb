module Softcover
  module Builders
    class Preview < Builder

      def build!
        if article?
          $stderr.puts "Previews not supported for articles"
          exit(1)
        end
        # Recall that MOBI generation makes an EPUB as a side-effect.
        Softcover::Builders::Mobi.new.build!(preview: true)
        Softcover::Builders::Pdf.new.build!(preview: true)
        extract_pdf_pages
      end

      private

        # Extracts pages from the PDF using GhostScript.
        # The page range is set by the `pdf_preview_page_range` parameter
        # in book.yml so that authors can override the default range.
        def extract_pdf_pages
          input  = File.join('ebooks', manifest.filename + '.pdf')
          output = input.sub('.pdf', '-preview.pdf')
          unless manifest.respond_to?(:pdf_preview_page_range)
            $stderr.puts("Error: Preview not built")
            $stderr.puts("Define pdf_preview_page_range in config/book.yml")
            $stderr.puts("See http://manual.softcover.io/book/getting_started#sec-build_preview")
            exit(1)
          end
          range = manifest.pdf_preview_page_range.split('..').map(&:to_i)
          cmd  = %(yes | #{ghostscript} -dBATCH -sOutputFile="#{output}")
          cmd += %( -dFirstPage=#{range.first} -dLastPage=#{range.last})
          cmd += %( -sDEVICE=pdfwrite "#{input}" > /dev/null 2> /dev/null)
          execute cmd
        end

        def ghostscript
          @ghostscript ||= executable(dependency_filename(:ghostscript))
        end
    end
  end
end