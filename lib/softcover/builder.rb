module Softcover
  class Builder
    include Softcover::Utils

    attr_accessor :manifest, :built_files

    def initialize
      @manifest = Softcover::BookManifest.new(verify_paths: true,
                                              source: source)
      @built_files = []
      ensure_style_file_locations
      write_polytexnic_commands_file
    end

    def build!(options={})
      setup
      build(options)
      verify
      self
    end

    def clean!; end

    private
      def setup; end
      def verify; end

      # Ensures the style files are in the right location.
      # This is for backwards compatibility.
      def ensure_style_file_locations
        styles_dir = Softcover::Directories::STYLES
        mkdir styles_dir
        fix_custom_include
        files = Dir.glob('*.sty')
        FileUtils.mv(files, styles_dir)
      end

      # Fixes the custom include.
      # The template includes the custom style file as an example
      # of file inclusion. Unfortunately, the location of 'custom.sty', has
      # changed, which will result in older templates spontaneously breaking.
      def fix_custom_include
        first_chapter = File.join('chapters', 'a_chapter.tex')
        if File.exist?(first_chapter)
          text = File.read(first_chapter)
          text.gsub!('<<(custom.sty',
                     "<<(#{Softcover::Directories::STYLES}/custom.sty" )
          File.write(first_chapter, text)
        end
      end

      # Writes out the PolyTeXnic commands from polytexnic.
      def write_polytexnic_commands_file
        styles_dir = File.join(Dir.pwd, Softcover::Directories::STYLES)
        Polytexnic.write_polytexnic_style_file(styles_dir)
      end
  end
end