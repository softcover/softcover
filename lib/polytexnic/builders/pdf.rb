module Polytexnic
  module Builders
    class Pdf < Builder

      def build!
        # Build the PolyTeX filename so it accepts both 'foo' and 'foo.tex'.
        basename = File.basename(@manifest.filename, '.tex')
        book_filename = basename + '.tex'
        polytex_filenames = @manifest.chapter_file_paths << book_filename
        polytex_filenames.each do |filename|
          polytex = File.open(filename) { |f| f.read }
          latex   = Polytexnic::Core::Pipeline.new(polytex).to_latex
          latex.gsub!(/\\include{(.*?)}/) do
            "\\include{#{$1}.tmp}"
          end
          File.open(Polytexnic::Utils.tmpify(filename), 'w') do |f|
            f.write(latex)
          end
        end
        write_pygments_file(:latex)
        cmd = "pdflatex #{Polytexnic::Utils.tmpify(book_filename)}"
        cmd += " > /dev/null" if Polytexnic.test?
        # Run the command twice to guarantee up-to-date cross-references.
        system("#{cmd} && #{cmd}")
        rename_pdf(basename)
      end

      private

        # Renames the temp PDF so that it matches the original filename.
        # For example, foo_bar.tex should produce foo_bar.pdf.
        def rename_pdf(basename)
          tmp_pdf = basename + '.tmp.pdf'
          pdf     = basename + '.pdf'
          File.rename(tmp_pdf, pdf)
        end

    end
  end
end