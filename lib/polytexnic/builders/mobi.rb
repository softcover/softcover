module Polytexnic
  module Builders
    class Mobi < Builder

      def build!
        kindlegen = `which kindlegen`.strip

        if kindlegen == ''
          url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
          puts "Error: You must install kindlegen to build mobi: #{url}"
          exit 1
        end

        Polytexnic::Builders::Epub.new.build!

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