module Polytexnic
  module Builders
    class Preview < Builder

      def build!
        raise 'dfjakldj'
        Polytexnic::Builders::Mobi.new.build!    # Builds EPUB as a side-effect
        Polytexnic::Builders::Pdf.new.build!
        pdf_split
      end

      private

        def pdf_split
          input  = File.join('ebooks', manifest.filename + '.pdf')
          output = input.sub('.pdf', '-preview.pdf')
          range  = manifest.pdf_preview_page_range.split('..').map(&:to_i)
          cmd  = %(yes | gs -dBATCH -sOutputFile="#{output}")
          cmd += %( -dFirstPage=#{range.first} -dLastPage=#{range.last})
          cmd += %( -sDEVICE=pdfwrite "#{input}" >& /dev/null)
          exec cmd
        end
    end
  end
end