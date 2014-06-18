module Softcover
  module Commands
    module EpubValidator
      extend Softcover::Utils
      extend self

      # Validates a book according to the EPUB standard.
      def validate!
        manifest = BookManifest.new(source: source)
        epub = path("ebooks/#{manifest.filename}.epub")
        if File.exist?(epub)
          puts "Validating EPUB..."
          system("#{java} -jar #{epubcheck} #{epub}")
        else
          puts "File '#{epub}' not found"
          puts "Run 'softcover build:epub' to generate"
          exit 1
        end
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
