require 'ostruct'

class Softcover::BookManifest < OpenStruct
  include Softcover::Utils

  class NotFound < StandardError
    def message
      "Invalid book directory, no manifest file found!"
    end
  end

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

    # Returns a chapter heading for use in the navigation menu.
    def menu_heading
      raw_html = Polytexnic::Pipeline.new(title).to_html
      html = Nokogiri::HTML(raw_html).at_css('p').inner_html
      chapter_number.zero? ? html : "Chapter #{chapter_number}: #{html}"
    end

    def to_hash
      marshal_dump.merge({ menu_heading: menu_heading })
    end

    def source
      case extension
      when '.md'
        :markdown
      when '.tex'
        :polytex
      end
    end

    def full_name
      "#{slug}#{extension}"
    end
  end

  class Section < OpenStruct
  end

  TXT_PATH  = 'Book.txt'
  YAML_PATH = "book.yml"

  def initialize(options = {})
    @source = options[:source] || :polytex
    @origin = options[:origin]
    yaml_attrs = read_from_yml
    attrs = case
            when polytex?  then yaml_attrs
            when markdown? then yaml_attrs.merge(read_from_md)
            else
              self.class.not_found!
            end.symbolize_keys!

    marshal_load attrs

    write_master_latex_file(self)

    if polytex?
      tex_filename = filename + '.tex'
      self.chapters = []
      self.frontmatter = []
      base_contents = File.read(tex_filename)
      if base_contents.match(/frontmatter/)
        @frontmatter = true
        chapters.push Chapter.new(slug:  'frontmatter',
                                  title: 'Frontmatter',
                                  sections: nil,
                                  chapter_number: 0)
      end
      raw_frontmatter = remove_frontmatter(base_contents, frontmatter)
      if frontmatter?
        self.frontmatter = chapter_includes(raw_frontmatter)
      else
        self.frontmatter = []
      end
      chapter_includes(base_contents).each_with_index do |name, i|
        slug = File.basename(name, '.*')
        chapter_title_regex = /^\s*\\chapter{(.*)}/
        content = File.read(File.join(polytex_dir, slug + '.tex'))
        chapter_title = content[chapter_title_regex, 1]
        j = 0
        sections = content.scan(/^\s*\\section{(.*)}/).flatten.map do |name|
          Section.new(name: name, section_number: j += 1)
        end
        chapters.push Chapter.new(slug: slug,
                                  title: chapter_title,
                                  sections: sections,
                                  chapter_number: i + 1)
      end
    end
    verify_paths! if options[:verify_paths]
  end

  # Returns the directory where the LaTeX files are located.
  # We put them in the a separate directory when using them as an intermediate
  # format when working with Markdown books. Otherwise, we use the chapters
  # directory, which is the default location when writing LaTeX/PolyTeX books.
  def polytex_dir
    dir = (markdown? || @origin == :markdown) ? 'generated_polytex' : 'chapters'
    mkdir dir
    dir
  end

  # Returns an array of the chapters to include.
  def chapter_includes(string)
    chapter_regex = /^\s*\\include\{#{polytex_dir}\/(.*?)\}/
    string.scan(chapter_regex).flatten
  end

  # Removes frontmatter.
  # The frontmatter shouldn't be included in the chapter slugs, so we remove
  # it. For example, in
  #  \frontmatter
  #  \maketitle
  #  \tableofcontents
  #  % List frontmatter sections here (preface, foreword, etc.).
  #  \include{chapters/preface}
  #  \mainmatter
  #  % List chapters here in the order they should appear in the book.
  #  \include{chapters/a_chapter}
  # we don't want to include the preface.
  def remove_frontmatter(base_contents, frontmatter)
    base_contents.gsub!(/\\frontmatter(.*)\\mainmatter/m, '')
    $1
  end

  # Returns true if the book has frontmatter.
  def frontmatter?
    @frontmatter
  end

  # Returns the first full chapter.
  # This arranges to skip the frontmatter, if any.
  def first_chapter
    frontmatter? ? chapters[1] : chapters[0]
  end

  # Returns true if converting Markdown source.
  def markdown?
    @source == :markdown || @source == :md
  end
  alias :md? :markdown?

  # Returns true if converting PolyTeX source.
  def polytex?
    @source == :polytex
  end

  # Returns an iterator for the chapter file paths.
  def chapter_file_paths
    pdf_chapter_names.map do |name|
      file_path = case
                  when markdown? || @origin == :markdown
                    chapter = chapters.find { |chapter| chapter.slug == name }
                    extension = chapter.nil? ? '.md' : chapter.extension
                    File.join("chapters", "#{name}#{extension}")
                  when polytex?
                    File.join("chapters", "#{name}.tex")
                  end

      yield file_path if block_given?

      file_path
    end
  end

  # Returns chapters for the PDF.
  def pdf_chapter_names
    chaps = chapters.reject { |chapter| chapter.slug.match(/frontmatter/) }.
                     collect(&:slug)
    frontmatter? ? frontmatter + chaps : chaps
  end

  # Returns the full chapter filenames for the PDF.
  def pdf_chapter_filenames
    pdf_chapter_names.map { |name| File.join(polytex_dir, "#{name}.tex") }
  end

  def find_chapter_by_slug(slug)
    chapters.find { |chapter| chapter.slug == slug }
  end

  def find_chapter_by_number(number)
    chapters.find { |chapter| chapter.chapter_number == number }
  end

  # Returns a URL for the chapter with the given number.
  def url(chapter_number)
    if (chapter = find_chapter_by_number(chapter_number))
      chapter.slug
    else
      '#'
    end
  end

  # Returns the chapter range for book previews.
  # We could `eval` the range, but that would allow users to execute arbitrary
  # code (maybe not a big problem on their system, but it would be a Bad Thing
  # on a server).
  def preview_chapter_range
    first, last = epub_mobi_preview_chapter_range.split('..').map(&:to_i)
    first..last
  end

  # Returns the chapters to use in the preview as a range.
  def preview_chapters
    chapters[preview_chapter_range]
  end

  def self.valid_directory?
    [YAML_PATH, TXT_PATH].any? { |f| File.exist?(f) }
  end

  # Changes the directory until in the book's root directory.
  def self.find_book_root!
    loop do
      return true if valid_directory?
      return not_found! if Dir.pwd == '/'
      Dir.chdir '..'
    end
  end

  def self.not_found!
    raise NotFound
  end

  # Returns the source files specified by Book.txt.
  # Allows a mixture of Markdown and PolyTeX files.
  def source_files
    self.class.find_book_root!
    md_tex = /.*(?:\.md|\.tex)/
    File.readlines(TXT_PATH).select { |path| path =~ md_tex }.map(&:strip)
  end

  def basenames
    source_files.map { |file| File.basename(file, '.*') }
  end

  def extensions
    source_files.map { |file| File.extname(file) }
  end

  def chapter_objects
    basenames.zip(extensions).map do |name, extension|
      Chapter.new(slug: name, extension: extension)
    end
  end

  def read_from_md
    { chapters: chapter_objects, filename: TXT_PATH }
  end


  private

    def read_from_yml
      require 'softcover/config'
      require 'yaml/store'
      self.class.find_book_root!
      YAML.load_file(YAML_PATH)
    end


    def verify_paths!
      chapter_file_paths do |chapter_path|
        next if chapter_path =~ /frontmatter/
        unless File.exist?(chapter_path)
          raise "Chapter file in manifest not found in #{chapter_path}"
        end
      end
    end
end