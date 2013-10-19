module Polytexnic
  module Builders
    class Pdf < Builder
      include Polytexnic::Output

      def build!(options={})
        if markdown_directory?
          # Build the HTML to produce PolyTeX as a side-effect,
          # then update the manifest to reduce PDF generation
          # to a previously solved problem.
          Polytexnic::Builders::Html.new.build!
          @manifest = Polytexnic::BookManifest.new(source: :polytex)
        end
        # Build the PolyTeX filename so it accepts both 'foo' and 'foo.tex'.
        basename = File.basename(@manifest.filename, '.tex')
        book_filename = basename + '.tex'
        polytex_filenames = @manifest.chapter_file_paths << book_filename
        polytex_filenames.delete('chapters/frontmatter.tex')
        polytex_filenames.each do |filename|
          puts filename
          polytex = File.open(filename) { |f| f.read }
          latex   = Polytexnic::Core::Pipeline.new(polytex).to_latex
          if filename == book_filename
            latex.gsub!(/\\include{(.*?)}/) do
              "\\include{#{$1}.tmp}"
            end
          end
          File.open(Polytexnic::Utils.tmpify(filename), 'w') do |f|
            f.write(latex)
          end
        end
        write_pygments_file(:latex)
        copy_polytexnic_sty
        build_pdf = "#{xelatex} #{Polytexnic::Utils.tmpify(book_filename)}"
        # Run the command twice to guarantee up-to-date cross-references.
        # Including the `mv` in the command is necessary because `execute`
        # below uses `exec` (except in tests, where it breaks). Since `exec`
        # causes the Ruby process to end, any commands executed after `exec`
        # would be ignored. The reason for using `exec`
        # is so that LaTeX errors get emitted to the screen rather than just
        # hanging the process.
        cmd = "#{build_pdf} ; #{build_pdf} ; #{rename_pdf(basename)}"
        options[:preview] ? system(cmd) : execute(cmd)
      end

      private

        def xelatex
          filename = `which xelatex`.chomp
          message  = "Install LaTeX (http://latex-project.org/ftp.html)"
          @xelatex ||= executable(filename, message)
        end

        # Returns the command to rename the temp PDF.
        # The purpose is to matche the original filename.
        # For example, foo_bar.tex should produce foo_bar.pdf.
        # While we're at it, we move it to the standard ebooks/ directory.
        def rename_pdf(basename)
          tmp_pdf = basename + '.tmp.pdf'
          pdf     = basename + '.pdf'
          mkdir('ebooks')
          "mv -f #{tmp_pdf} #{File.join('ebooks', pdf)}"
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