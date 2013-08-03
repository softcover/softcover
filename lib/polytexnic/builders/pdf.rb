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
        write_polytexnic_commands_file
        copy_polytexnic_sty
        cmd = "#{xelatex} #{Polytexnic::Utils.tmpify(book_filename)}"
        # Run the command twice to guarantee up-to-date cross-references.
        system("#{cmd} && #{cmd}")
        rename_pdf(basename)
      end

      private

        def xelatex
          filename = `which xelatex`.chomp
          message  = "Install LaTeX (http://latex-project.org/ftp.html)"
          @inkscape ||= executable(filename, message)
        end

        # Renames the temp PDF so that it matches the original filename.
        # For example, foo_bar.tex should produce foo_bar.pdf.
        # While we're at it, we move it to the standard ebooks/ directory.
        def rename_pdf(basename)
          tmp_pdf = basename + '.tmp.pdf'
          pdf     = basename + '.pdf'
          mkdir('ebooks')
          FileUtils.mv(tmp_pdf, File.join('ebooks', pdf))
        end

        # Writes out the PolyTeXnic commands from polytexnic-core.
        def write_polytexnic_commands_file
          File.open('polytexnic_commands.sty', 'w') do |f|
            f.write(Polytexnic::Core::Utils.new_commands)
          end
        end

        # Copies the PolyTeXnic style file to ensure it's always fresh.
        def copy_polytexnic_sty
          polytexnic_sty = 'polytexnic.sty'
          source_sty     = File.join(File.dirname(__FILE__),
                                     "../template/#{polytexnic_sty}")
          FileUtils.cp source_sty, polytexnic_sty
        end

    end
  end
end