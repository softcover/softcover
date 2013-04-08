module Polytexnic
  module Builders
    class Pdf < Builder

      def build!
        # Build the PolyTeX filename so it accepts both 'foo' and 'foo.tex'.
        basename = File.basename(@manifest.filename, '.tex')
        polytex_filename = basename + '.tex'
        latex_filename   = basename + '.tmp.tex'
        # TODO: Follow the includes to ensure polytex contains all the content.
        polytex = File.open(polytex_filename) { |f| f.read }
        latex   = Polytexnic::Core::Pipeline.new(polytex).to_latex
        File.open(latex_filename, 'w') { |f| f.write(latex) }
        cmd = "pdflatex #{latex_filename}"
        cmd += " > /dev/null" if Polytexnic.test?
        # Run the command twice to guarantee up-to-date cross-references.
        system("#{cmd} && #{cmd}")
        rename_pdf(latex_filename)
      end

      private

        # Renames the temp PDF so that it matches the original filename.
        # For example, foo_bar.tex should produce foo_bar.pdf.
        def rename_pdf(latex_filename)
          tmp_pdf = File.basename(latex_filename, '.tmp.tex') + '.tmp.pdf'
          pdf     = File.basename(latex_filename, '.tmp.tex') + '.pdf'
          File.rename(tmp_pdf, pdf)
        end

    end
  end
end