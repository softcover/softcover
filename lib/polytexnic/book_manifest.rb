require 'ostruct'
require 'active_support/core_ext/hash'

class Polytexnic::BookManifest < OpenStruct

  class Chapter < OpenStruct
    def path
      File.join('chapters', slug + '.tex')
    end

    def fragment_name
      "#{slug}_fragment.html"
    end

    def fragment_path
      File.join('html', fragment_name)
    end

    def nodes
      @nodes ||= []
    end
  end

  class Section < OpenStruct
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
      base_contents = File.read(tex_filename)
      self.author = base_contents.scan(/\\author\{(.*?)\}/).flatten.first
      chapter_regex = /\\include\{chapters\/(.*?)\}/
      chapter_includes = base_contents.scan(chapter_regex).flatten
      chapter_includes.each_with_index do |slug, i|
        title_regex = /\\chapter\{(.*?)\}/m
        content = File.read(File.join('chapters', slug + '.tex'))
        title = content[title_regex, 1]
        j = 0
        sections = content.scan(/\\section{(.*?)}/m).flatten.map do |name|
          Section.new(name: name, section_number: j += 1)
        end
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

  def find_chapter_by_slug(slug)
    chapters.find { |chapter| chapter.slug == slug }
  end

  def self.valid_directory?
    [YAML_PATH, MD_PATH].any? { |f| File.exist?(f) }
  end

  private
    def read_from_yml
      require 'polytexnic/config'
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