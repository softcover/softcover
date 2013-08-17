module Polytexnic
  class Builder
    include Polytexnic::Utils

    attr_accessor :manifest, :built_files

    def initialize
      @manifest = Polytexnic::BookManifest.new(verify_paths: true,
                                               source: source)
      @built_files = []
    end

    def build!
      setup
      build
      verify
      self
    end

    def clean!; end

    private
      def setup; end
      def verify; end

      def source
        File.directory?('markdown') ? :markdown : :polytex
      end
  end
end