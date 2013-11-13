module Polytexnic
  module Commands
    module EpubValidator
      extend Polytexnic::Utils
      extend self

      # Validates a book according to the EPUB standard.
      def validate!
        epub = Dir.glob('ebooks/*.epub').first
        puts "Validating EPUB..."
        system("#{java} -jar #{epubcheck} #{epub}")
      end

      private

        def java
          filename = `which java`.chomp
          url = 'http://www.java.com/en/download/help/index_installing.xml'
          message = "Install Java (#{url})"
          @java ||= executable(filename, message)
        end

        def epubcheck
          filename = File.join(Dir.home, 'epubcheck-3.0', 'epubcheck-3.0.jar')
          url = 'https://code.google.com/p/epubcheck/downloads/' +
                'detail?name=epubcheck-3.0.zip'
          message = "Put EpubCheck (#{url}) in your home directory"
          @epubcheck ||= executable(filename, message).inspect
        end
    end
  end
end
