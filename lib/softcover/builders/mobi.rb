module Softcover
  module Builders
    class Mobi < Builder
      include Softcover::Utils
      include Softcover::EpubUtils

      def build!(options={})
        Softcover::Builders::Epub.new.build!(options)
        filename = mobi_filename(options)
        command  = mobi_command(filename, options)
        silent   = options[:silent] || Softcover.test?
        if options[:quiet] || silent
          silence { system(command) }
        else
          system(command)
        end
      end

      # Returns the filename of the MOBI (preview if necessary).
      def mobi_filename(options={})
        options[:preview] ? manifest.filename + '-preview' : manifest.filename
      end

      # Returns the command for making a MOBI, based on the options.
      def mobi_command(filename, options={})
        silent = options[:silent] || Softcover.test?
        if options[:kindlegen] || options[:amazon]
          cmd = "#{kindlegen} ebooks/#{filename}.epub"
        else
          cmd = "#{calibre} ebooks/#{filename}.epub ebooks/#{filename}.mobi" +
                " #{calibre_options}"
        end
        puts cmd unless (options[:quiet] || silent)
        cmd
      end

      private

        def calibre
          @calibre ||= executable(dependency_filename(:calibre))
        end

        # Returns the options for the Calibre `ebook-convert` CLI.
        def calibre_options
          # Include both Mobipocket & KF8 formats.
          # Figuring this out took around two years. It really should be
          # the Calibre default.
          opts = ["--mobi-file-type both"]
          # Don't put pagebreaks in the detailed table of contents.
          opts << "--chapter /"
          if cover?
            # Add an explicit path to the cover image.
            # Figuring this out took several days.
            opts << "--cover #{cover_img_path}"
            # Get covers to work in Kindle desktop app.
            opts << "--share-not-sync"
          end
          opts.join(" ")
        end

        def kindlegen
          @kindlegen ||= executable(dependency_filename(:kindlegen))
        end
    end
  end
end