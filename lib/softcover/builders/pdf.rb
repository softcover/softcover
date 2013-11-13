module Softcover
  module Builders
    class Pdf < Builder
      include Softcover::Output

      def build!(options={})
        if manifest.markdown?
          # Build the HTML to produce PolyTeX as a side-effect,
          # then update the manifest to reduce PDF generation
          # to a previously solved problem.
          Softcover::Builders::Html.new.build!(options.merge(preserve_tex:
                                                              true))
          self.manifest = Softcover::BookManifest.new(source: :polytex)
          @remove_tex = true unless options[:preserve_tex]
        end
        # Build the PolyTeX filename so it accepts both 'foo' and 'foo.tex'.
        basename = File.basename(@manifest.filename, '.tex')
        book_filename = basename + '.tex'

        # In debug mode, execute `xelatex` and exit.
        if options[:debug]
          execute "#{xelatex} #{book_filename}"
          return    # only gets called in test env
        elsif options[:'find-overfull']
          tmp_name = book_filename.sub('.tex', '.tmp.tex')
          # The we do things, code listings show up as "Overfull", but they're
          # actually fine, so filter them out.
          filter_out_listings = "grep -v 3.22281pt"
          # It's hard to correlate Overfull line numbers with source files,
          # so we use grep's -A flag to provide some context instead. Authors
          # can then use their text editors to find the corresponding place
          # in the text.
          show_context = 'grep -A 3 "Overfull \hbox"'
          cmd = "xelatex #{tmp_name} | #{filter_out_listings} | #{show_context}"
          execute cmd
          return
        end

        polytex_filenames = @manifest.chapter_file_paths << book_filename
        polytex_filenames.delete(path('chapters/frontmatter.tex'))
        polytex_filenames.each do |filename|
          puts filename unless options[:quiet] || options[:silent]
          polytex = File.open(filename) { |f| f.read }
          latex   = Polytexnic::Core::Pipeline.new(polytex).to_latex
          if filename == book_filename
            latex.gsub!(/\\include{(.*?)}/) do
              "\\include{#{Softcover::Utils.tmpify($1)}.tmp}"
            end
          end
          File.open(Softcover::Utils.tmpify(filename), 'w') do |f|
            f.write(latex)
          end
        end
        write_pygments_file(:latex)
        copy_polytexnic_sty

        remove_polytex! if remove_polytex?

        build_pdf = "#{xelatex} #{Softcover::Utils.tmpify(book_filename)}"
        # Run the command twice (to guarantee up-to-date cross-references)
        # unless explicitly overriden.
        # Renaming the PDF in the command is necessary because `execute`
        # below uses `exec` (except in tests, where it breaks). Since `exec`
        # causes the Ruby process to end, any Ruby code after `exec`
        # is ignored.
        # (The reason for using `exec` is so that LaTeX errors get emitted to
        # the screen rather than just hanging the process.)
        pdf_cmd = options[:once] ? build_pdf : "#{build_pdf} ; #{build_pdf}"
        cmd = "#{pdf_cmd} ; #{rename_pdf(basename)}"
        # Here we use `system` when making a preview because the preview command
        # needs to run after the main PDF build.
        if options[:quiet] || options[:silent]
          silence { options[:preview] ? system(cmd) : execute(cmd) }
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