module Polytexnic
  module Commands
    module Build
      extend self

      def for_format(format)
        raise 'Invalid format' unless Polytexnic::FORMATS.include?(format)
        print "Building #{format.upcase}..."
        builder_for(format).build!
        puts "Done."
      end

      def all_formats
        puts 'Building all formats...'
        Polytexnic::FORMATS.each do |format|
          builder_for(format).build!
        end
      end

      def builder_for(format)
        "Polytexnic::Builders::#{format.titleize}".constantize.new
      end
    end
  end
end
