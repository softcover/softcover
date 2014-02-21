module Softcover
  module Builders
    class Mobi < Builder

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
        if options[:calibre]
          FileUtils.mv("ebooks/#{filename}.azw3", "ebooks/#{filename}.mobi")
          puts "MOBI saved to ebooks/#{filename}.mobi" unless silent
        end
      end

      # Returns the filename of the MOBI (preview if necessary).
      def mobi_filename(options={})
        options[:preview] ? manifest.filename + '-preview' : manifest.filename
      end

      # Returns the command for making a MOBI, based on the options.
      def mobi_command(filename, options={})
        if options[:calibre]
          "#{calibre} ebooks/#{filename}.epub ebooks/#{filename}.azw3"
        else
          "#{kindlegen} ebooks/#{filename}.epub"
        end
      end

      private

        def calibre
          @calibre ||= executable(dependency_filename(:calibre))
        end

        def kindlegen
          @kindlegen ||= executable(dependency_filename(:kindlegen))
        end
    end
  end
end