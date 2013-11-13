module Softcover
  module Commands
    module Build
      include Softcover::Output
      extend self

      # Builds the book for the given format.
      def for_format(format, options={})
        raise 'Invalid format' unless Softcover::FORMATS.include?(format)
        building_message(format.upcase, options)
        builder_for(format).build!(options)
        if format == 'html' && !(options[:silent] || options[:quiet])
          puts "LaTeX-to-XML debug information output to log/tralics.log"
        end
      end

      # Builds the book for all formats.
      def all_formats(options={})
        building_message('all formats', options)
        Softcover::BUILD_ALL_FORMATS.each do |format|
          if format == 'mobi'
            building_message('EPUB & MOBI', options)
          else
            building_message(format.upcase, options)
          end
          builder_for(format).build!(options)
        end
      end

      # Builds the book preview.
      def preview(options={})
        building_message('preview', options)
        builder_for('preview').build!
      end

      # Returns the builder for the given format.
      def builder_for(format)
        "Softcover::Builders::#{format.titleize}".constantize.new
      end

      private

        # Shows a message when building a particular format.
        def building_message(format, options={})
          unless options[:silent] || options[:'find-overfull']
            puts "Building #{format}..."
          end
        end
    end
  end
end
