module Polytexnic
  module Builders
    class Mobi < Builder

      def build!
        Polytexnic::Builders::Epub.new.build!
        command = "#{kindlegen} ebooks/#{manifest.filename}.epub"
        if Polytexnic.test?
          command
        else
          system(command)
        end
      end

      private

        def kindlegen
          filename = `which kindlegen`.chomp
          url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
          message  = "Install LaTeX (#{url})"
          @kindlegen ||= executable(filename, message)
        end
    end
  end
end