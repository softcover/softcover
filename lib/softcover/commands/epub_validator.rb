module Softcover
  module Commands
    module EpubValidator
      extend Softcover::Utils
      extend self

      # Validates a book according to the EPUB standard.
      def validate!
        epub = Dir.glob('ebooks/*.epub').first
        puts "Validating EPUB..."
        system("#{java} -jar #{epubcheck} #{epub}")
      end

      private

        def java
          @java ||= executable(dependency_filename(:java))
        end

        def epubcheck
          @epubcheck ||= executable(dependency_filename(:epubcheck)).inspect
        end
    end
  end
end
