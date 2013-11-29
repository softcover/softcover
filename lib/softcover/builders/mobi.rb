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
        unless options[:kindlegen]
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
        if options[:kindlegen]
          "#{kindlegen} ebooks/#{filename}.epub"
        else
          "#{calibre} ebooks/#{filename}.epub ebooks/#{filename}.azw3"
        end
      end

      private

        def calibre
          filename = `which ebook-convert`.chomp
          url = 'http://calibre-ebook.com/'
          message  = "Install Calibre (#{url}) and enable command line tools"
          message += " (http://manual.calibre-ebook.com/cli/cli-index.html)"
          @calibre ||= executable(filename, message)
        end

        def kindlegen
          filename = `which kindlegen`.chomp
          url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
          message  = "Install kindlegen (#{url})"
          @kindlegen ||= executable(filename, message)
        end
    end
  end
end