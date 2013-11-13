module Softcover
  class Builder
    include Softcover::Utils

    attr_accessor :manifest, :built_files

    def initialize
      @manifest = Softcover::BookManifest.new(verify_paths: true,
                                               source: source)
      @built_files = []
      write_polytexnic_commands_file
    end

    def build!(options={})
      setup
      build(options)
      verify
      self
    end

    # Returns true if we should remove the generated PolyTeX.
    # This is true of Markdown books, but we can't just use `markdown?` because
    # we're re-using the PolyTeX production pipeline.
    def remove_polytex?
      @remove_tex
    end

    # Removes the generated PolyTeX.
    # The 'removal' actually just involves moving it to an ignored storage
    # directory. This gives users the ability to inspect it if desired.
    def remove_polytex!
      mkdir 'generated_polytex'
      FileUtils.mv(Dir.glob(path('chapters/*.tex')), 'generated_polytex')
    end

    def clean!; end

    private
      def setup; end
      def verify; end

      def source
        Dir.glob(path('chapters/*.md')).empty? ? :polytex : :markdown
      end

      # Writes out the PolyTeXnic commands from polytexnic.
      def write_polytexnic_commands_file
        Polytexnic.write_polytexnic_style_file(Dir.pwd)
      end
  end
end