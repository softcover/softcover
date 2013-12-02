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

    def clean!; end

    private
      def setup; end
      def verify; end

      # Writes out the PolyTeXnic commands from polytexnic.
      def write_polytexnic_commands_file
        Polytexnic.write_polytexnic_style_file(Dir.pwd)
      end
  end
end