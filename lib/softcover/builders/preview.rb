module Softcover
  module Builders
    class Preview < Builder

      def build!
        # Recall that MOBI generation makes an EPUB as a side-effect.
        Softcover::Builders::Mobi.new.build!(preview: true)
        Softcover::Builders::Pdf.new.build!(preview: true)
      end

    end
  end
end