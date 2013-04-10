module Polytexnic
  module Builders
    class Mobi < Builder

      def build!
        Polytexnic::Builders::Epub.new.build!
        kindlegen = `which kindlegen`.strip
        command = "#{kindlegen} epub/#{manifest.filename}.epub"
        if Polytexnic.test?
          command
        else
          system(command)
        end
      end

    end
  end
end