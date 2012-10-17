module Polytexnic
  class Builder
    attr_accessor :chapter_manifest, :built_files

    def initialize
      @chapter_manifest = Polytexnic::ChapterManifest.new verify_paths: true
      @built_files = []
    end

    def build!
      setup
      build 
      verify
      self
    end

    private
      def build; end
      def setup; end
      def verify; end
  end
end