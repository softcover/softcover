module Softcover
  module Builders
    class Pdf < Builder
      include Softcover::Output
      include Softcover::Utils

      def build!(options={})
        if manifest.markdown?
          # Build the HTML to produce PolyTeX as a side-effect,
          # then update the manifest to reduce PDF generation
          # to a previously solved problem.
          Softcover::Builders::Html.new.build!
          self.manifest = Softcover::BookManifest.new(source: :polytex,
                                                      origin: :markdown)
        end

        write_master_latex_file(manifest)

        # Build the PolyTeX filename so it accepts both 'foo' and 'foo.tex'.
        basename = File.basename(manifest.filename, '.tex')
        book_filename = basename + '.tex'

        # In debug mode, execute `xelatex` and exit.
        if options[:debug]
          execute "#{xelatex} #{book_filename}"
          return    # only gets called in test env
        end

        polytex_filenames = manifest.pdf_chapter_filenames << book_filename
        polytex_filenames.each do |filename|
          polytex = File.open(filename) { |f| f.read }
          latex   = Polytexnic::Pipeline.new(polytex).to_latex
          if filename == book_filename
            latex.gsub!(/\\include{(.*?)}/) do
              "\\include{#{Softcover::Utils.tmpify(manifest, $1)}.tmp}"
            end
          end
          File.open(Softcover::Utils.tmpify(manifest, filename), 'w') do |f|
            f.write(latex)
          end
        end
        write_pygments_file(:latex)
        copy_polytexnic_sty

        # Renaming the PDF in the command is necessary because `execute`
        # below uses `exec` (except in tests, where it breaks). Since `exec`
        # causes the Ruby process to end, any Ruby code after `exec`
        # is ignored.
        # (The reason for using `exec` is so that LaTeX errors get emitted to
        # the screen rather than just hanging the process.)
        cmd = "#{pdf_cmd(book_filename, options)} ; #{rename_pdf(basename)}"
        # Here we use `system` when making a preview because the preview command
        # needs to run after the main PDF build.
        if options[:quiet] || options[:silent]
          silence_stream(STDERR) do
            silence { options[:preview] ? system(cmd) : execute(cmd) }
          end
        elsif options[:'find-overfull']
          silence_stream(STDERR) { execute(cmd) }
        else
          options[:preview] ? system(cmd) : execute(cmd)
        end
      end

      private

        # Returns the `xelatex` executable.
        # The `xelatex` program is roughly equivalent to the more standard
        # `pdflatex`, but has better support for Unicode.
        def xelatex
          filename = `which xelatex`.chomp
          message  = "Install LaTeX (http://latex-project.org/ftp.html)"
          @xelatex ||= executable(filename, message)
        end

        # Returns the command to build the PDF (once).
        def build_pdf(book_filename, options={})
          tmp_filename = Softcover::Utils.tmpify(manifest, book_filename)
          "#{xelatex} #{tmp_filename} #{options[:filters]}"
        end

        # Returns the full command to build the PDF.
        def pdf_cmd(book_filename, options={})
          if options[:once]
            build_pdf(book_filename)
          elsif options[:'find-overfull']
            # The way we do things, code listings show up as "Overfull", but
            # they're actually fine, so filter them out.
            filter_out_listings = "grep -v 3.22281pt"
            # Because each chapter typically lives in a separate file, it's
            # hard to correlate Overfull line numbers with lines in the source,
            # so we use grep's -A flag to provide some context instead. Authors
            # can then use their text editors' search function to find the
            # corresponding place in the text.
            show_context = 'grep -A 3 "Overfull \\\\\\\\hbox"'
            build_pdf(book_filename,
                      filters: "| #{filter_out_listings} | #{show_context}" )
          else
            # Run the command twice (to guarantee up-to-date cross-references).
            cmd = build_pdf(book_filename)
            "#{cmd} ; #{cmd}"
          end
        end

        # Returns the command to rename the temp PDF.
        # The purpose is to match the original filename.
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
          polytexnic_sty = 'softcover.sty'
          source_sty     = File.join(File.dirname(__FILE__),
                                     "../template/#{polytexnic_sty}")
          FileUtils.cp source_sty, polytexnic_sty
        end
    end
  end
end