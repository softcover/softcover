require 'ostruct'
require 'active_support/core_ext/hash'

class Polytexnic::BookManifest < OpenStruct

  class Chapter < OpenStruct; end

  YAML_PATH = "book.yml"
  JSON_PATH = "book.json"

  MD_PATH = "Book.txt"

  def initialize(opts={})
    attrs = case
    when md? then read_from_md
    when polytex? then read_from_yml
    else
      fail
    end.symbolize_keys!

    n = 0
    attrs[:chapters].map! do |chapter|
      case chapter
      when Hash then slug, title = chapter.first[0], chapter.first[1]
      when String then slug, title = chapter, chapter.titleize
      end

      Chapter.new slug: slug, title: title, chapter_number: n += 1
    end

    marshal_load attrs

    verify_paths! if opts[:verify_paths]
  end

  def md?
    File.exists?(MD_PATH)
  end

  def polytex?
    File.exists?(YAML_PATH)
  end

  def chapter_file_paths
    chapters.map do |chapter|
      file_path = case
      when md? then chapter.slug
      when polytex? then "chapters/#{chapter_path.slug}.tex"
      end

      yield file_path if block_given?

      file_path
    end
  end

  private
    def read_from_yml
      YAML.load_file YAML_PATH
    end

    def read_from_md
      return false unless 

      f = File.open(MD_PATH) 
      chapters = f.readlines.map { |path| path.gsub /\n/,'' }
      f.close

      {chapters: chapters}
    end

    def fail
      # TODO: raise error with instructions on adding a chapter manifest
      raise "No manifest file found!"
    end

    def verify_paths!
      chapter_file_paths do |chapter_path|
        unless File.exists?(chapter_path)
          raise "Chapter file in manifest not found" 
        end
      end
    end
end