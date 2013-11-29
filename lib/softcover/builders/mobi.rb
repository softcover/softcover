module Softcover
  module Builders
    class Mobi < Builder

      def build!(options={})
        Softcover::Builders::Epub.new.build!(options)
        filename  = manifest.filename
        filename += '-preview' if options[:preview]
        if options[:kindlegen]
          command = "#{kindlegen} ebooks/#{filename}.epub"
        else
          command = "#{calibre} ebooks/#{filename}.epub ebooks/#{filename}.azw3"
        end
        # Because of the way kindlegen uses tempfiles, testing for the
        # actual generation of the MOBI causes an error, so in tests
        # we just return the command.
        if options[:quiet] || options[:silent]
          silence { Softcover.test? ? command : system(command) }
        else
          Softcover.test? ? command : system(command)
        end
        unless Softcover.test? || options[:kindlegen]
          FileUtils.mv("ebooks/#{filename}.azw3", "ebooks/#{filename}.mobi")
          puts "MOBI saved to ebooks/#{filename}.mobi" unless options[:silent]
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