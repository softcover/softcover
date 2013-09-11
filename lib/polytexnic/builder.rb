module Polytexnic
  class Builder
    include Polytexnic::Utils

    attr_accessor :manifest, :built_files

    def initialize
      @manifest = Polytexnic::BookManifest.new(verify_paths: true,
                                               format: format)
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

      def format
        markdown? ? :markdown : :polytex
      end

      def markdown?
        File.directory?('markdown')
      end
  end
end