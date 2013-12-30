module Softcover
  module Builders
    class Preview < Builder

      def build!
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
          range  = manifest.pdf_preview_page_range.split('..').map(&:to_i)
          cmd  = %(yes | #{ghostscript} -dBATCH -sOutputFile="#{output}")
          cmd += %( -dFirstPage=#{range.first} -dLastPage=#{range.last})
          cmd += %( -sDEVICE=pdfwrite "#{input}" &> /dev/null)
          execute cmd
        end

        def ghostscript
          filename = `which gs`.chomp
          message  = "Install GhostScript (should come with LaTeX)"
          @ghostscript ||= executable(filename, message)
        end
    end
  end
end