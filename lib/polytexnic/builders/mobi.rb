module Polytexnic
  module Builders
    class Mobi < Builder

      def build!(options={})
        Polytexnic::Builders::Epub.new.build!(options)
        filename  = manifest.filename
        filename += '-preview' if options[:preview]
        command = "#{kindlegen} ebooks/#{filename}.epub"
        # Because of the way kindlegen uses tempfiles, testing for the
        # actual generation of the MOBI causes an error, so in tests
        # we just return the command.
        if options[:quiet] || options[:silent]
          silence { Polytexnic.test? ? command : system(command) }
        else
          Polytexnic.test? ? command : system(command)
        end
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