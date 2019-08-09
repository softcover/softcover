module Softcover
  module Builders
    class Pdf < Builder
      include Softcover::Output
      include Softcover::Utils

      def build!(options={})
        make_png_from_gif
        if manifest.markdown?
          # Build the HTML to produce PolyTeX as a side-effect,
          # then update the manifest to reduce PDF generation
          # to a previously solved problem.
          Softcover::Builders::Html.new.build!
          opts = options.merge({ source: :polytex, origin: :markdown})
          self.manifest = Softcover::BookManifest.new(opts)
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
          polytex = File.read(filename)
          latex   = Polytexnic::Pipeline.new(polytex,
                                             language_labels: language_labels).
                                            to_latex
          if filename == book_filename
            latex.gsub!(/\\include{(.*?)}/) do
              "\\include{#{Softcover::Utils.tmpify(manifest, $1)}.tmp}"
            end
          end
          File.write(Softcover::Utils.tmpify(manifest, filename), latex)
        end
        write_pygments_file(:latex, Softcover::Directories::STYLES)
        copy_polytexnic_sty(options)

        # Renaming the PDF in the command is necessary because `execute`
        # below uses `exec` (except in tests, where it breaks). Since `exec`
        # causes the Ruby process to end, any Ruby code after `exec`
        # is ignored.
        # (The reason for using `exec` is so that LaTeX errors get emitted to
        # the screen rather than just hanging the process.)
        cmd = "#{pdf_cmd(book_filename, options)} " +
              "; #{rename_pdf(basename, options)}"
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
          @xelatex ||= executable(dependency_filename(:latex))
        end

        # Make a PNG for each GIF in the images/ directory.
        def make_png_from_gif
          gif_pattern = File.join('images', '**', '*.gif')
          gif_files = Dir.glob(gif_pattern).reject { |f| File.directory?(f) }
          gif_files.each do |gif|
            dir = File.dirname(gif)
            ext = File.extname(gif)
            img = File.basename(gif, ext)
            png = File.join(dir, "#{img}.png")
            system "#{convert} #{gif} #{png}"
          end
        end

        # Returns the executable to ImageMagick's `convert` program.
        def convert
          @convert ||= executable(dependency_filename(:convert))
        end

        # Returns the command to build the PDF (once).
        def build_pdf(book_filename, options={})
          tmp_filename = Softcover::Utils.tmpify(manifest, book_filename)
          if options[:nonstop] || options[:silent] || options[:quiet]
            # Use nonstop to prevent LaTeX from hanging in quiet/silent mode.
            nonstop = "--interaction=nonstopmode"
            "#{xelatex} #{nonstop} #{tmp_filename} #{options[:filters]}"
	        else
            "#{xelatex} #{tmp_filename} #{options[:filters]}"
          end
        end

        # Returns the full command to build the PDF.
        def pdf_cmd(book_filename, options={})
          if options[:once]
            build_pdf(book_filename, options)
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
            cmd = build_pdf(book_filename, options)
            "#{cmd} ; #{cmd}"
          end
        end

        # Returns the command to rename the temp PDF.
        # The purpose is to match the original filename.
        # For example, foo_bar.tex should produce foo_bar.pdf.
        # While we're at it, we move it to the standard ebooks/ directory.
        def rename_pdf(basename, options={})
          tmp_pdf = basename + '.tmp.pdf'
          name    = options[:preview] ? basename + '-preview' : basename
          pdf     = name + '.pdf'
          mkdir('ebooks')
          # Remove the intermediate tmp files unless only running once.
          rm_tmp = keep_tmp_files?(options) ? "" : "&& rm -f *.tmp.*"
          "mv -f #{tmp_pdf} #{File.join('ebooks', pdf)} #{rm_tmp}"
        end

        # Keeps tmp files when running once, including when finding overfull.
        # The main purpose is to keep the *.aux files around for the ToC, xrefs,
        # etc.
        def keep_tmp_files?(options)
          options[:once] || options[:'find-overfull'] || Softcover.test?
        end

        # Copies the style file to ensure it's always fresh.
        def copy_polytexnic_sty(options)
          # TODO: uncomment back, handle Linux fonts
          # softcover_sty  = File.join(Softcover::Directories::STYLES,
          #                            'softcover.sty')
          # source_sty     = File.join(Softcover::Utils.template_dir(options), 
          #                            softcover_sty)
          # FileUtils.cp source_sty, softcover_sty
        end
    end
  end
end
