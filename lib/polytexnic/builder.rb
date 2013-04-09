module Polytexnic
  class Builder
    attr_accessor :manifest, :built_files

    def initialize
      @manifest = Polytexnic::BookManifest.new verify_paths: true
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
      def build; end
      def setup; end
      def verify; end
  end
end