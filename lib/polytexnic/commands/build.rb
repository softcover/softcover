module Polytexnic
  module Commands
    module Build
      include Polytexnic::Output
      extend self

      def for_format(format, options={})
        raise 'Invalid format' unless Polytexnic::FORMATS.include?(format)
        building_message(format.upcase, options)
        builder_for(format).build!(options)
        if format == 'html' && !(options[:silent] || options[:quiet])
          puts "LaTeX-to-XML debug information output to log/tralics.log"
        end
      end

      def all_formats(options={})
        building_message('all formats', options)
        Polytexnic::BUILD_ALL_FORMATS.each do |format|
          builder_for(format).build!(options)
        end
      end

      def preview(options={})
        building_message('preview', options)
        builder_for('preview').build!
      end

      def builder_for(format)
        "Polytexnic::Builders::#{format.titleize}".constantize.new
      end

      private

        def building_message(content, options={})
          puts "Building #{content}..." unless options[:silent]
        end
    end
  end
end
