module Polytexnic
  module Commands
    module Build
      extend self

      def for_format(format)
        raise 'Invalid format' unless Polytexnic::FORMATS.include?(format)
        puts "Building #{format.upcase}..."
        builder_for(format).build!
        puts "Done."
        if format == 'html'
          puts "Tralics debug information ouput to log/tralics.log"
        end
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
