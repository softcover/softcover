require 'ostruct'
require 'active_support/core_ext/hash'

class Polytexnic::BookManifest < OpenStruct

  class Chapter < OpenStruct
    def path
      File.join('chapters', slug + '.tex')
    end
  end

  YAML_PATH = "book.yml"
  MD_PATH = "Book.txt"

  def initialize(opts={})
    attrs = case
    when md? then read_from_md
    when polytex? then read_from_yml
    else
      fail
    end.symbolize_keys!

    marshal_load attrs

    if polytex?
      tex_filename = filename + '.tex'
      self.chapters = []
      chapter_regex = /\\include\{chapters\/(.+?)\}/
      chapter_includes = File.read(tex_filename).scan(chapter_regex).flatten
      chapter_includes.each_with_index do |slug, i|
        title_regex = /\\chapter\{(.*?)\}/m
        content = File.read(File.join('chapters', slug + '.tex'))
        title = content[title_regex, 1]
        sections = content.scan(/\\section\{(.*?)}/m).flatten
        chapters.push Chapter.new(slug: slug,
                                  title: title,
                                  sections: sections,
                                  chapter_number: i += 1)
      end
    end

    # TODO: verify all attributes

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
      when polytex? then "chapters/#{chapter.slug}.tex"
      end

      yield file_path if block_given?

      file_path
    end
  end

  def self.valid_directory?
    [YAML_PATH, MD_PATH].any?{ |f| File.exist?(f) }
  end

  private
    def read_from_yml
      YAML.load_file YAML_PATH
    end

    def read_from_md
      return false unless f = File.open(MD_PATH)

      chapters = f.readlines.each_with_index.map do |path,i|
        slug = path.gsub(/\n/,'')
        # TODO: read title from chapter file
        Chapter.new slug: slug, title: slug, chapter_number: i + 1
      end
      f.close

      { chapters: chapters, filename: MD_PATH }
    end

    def fail
      # TODO: raise error with instructions on adding a chapter manifest
      raise "No manifest file found!"
    end

    def verify_paths!
      chapter_file_paths do |chapter_path|
        unless File.exist?(chapter_path)
          raise "Chapter file in manifest not found"
        end
      end
    end
end