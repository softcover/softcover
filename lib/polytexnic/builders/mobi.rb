module Polytexnic
  module Builders
    class Mobi < Builder

      def build!
        Polytexnic::Builders::Epub.new.build!
        if markdown_directory?
          @manifest = Polytexnic::BookManifest.new(source: :polytex)
        end
        command = "#{kindlegen} ebooks/#{manifest.filename}.epub"
        Polytexnic.test? ? command : system(command)
      end

      private

        def kindlegen
          filename = `which kindlegen`.chomp
          url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
          message  = "Install kindlegen (#{url})"
          @kindlegen ||= executable(filename, message)
        end
    end
  end
end