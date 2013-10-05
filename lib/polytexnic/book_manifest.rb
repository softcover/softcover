require 'ostruct'

class Polytexnic::BookManifest < OpenStruct
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
      raw_html = Polytexnic::Core::Pipeline.new(title).to_html
      html = Nokogiri::HTML(raw_html).at_css('p').inner_html
      chapter_number.zero? ? html : "Chapter #{chapter_number}: #{html}"
    end
  end

  class Section < OpenStruct
  end

  MD_PATH = File.join('markdown', 'Book.txt')
  YAML_PATH = "book.yml"

  def initialize(options = {})
    @source = options[:source] || :polytex
    yaml_attrs = read_from_yml
    @force_polytex = yaml_attrs["force_polytex"]
    if @force_polytex && File.directory?('markdown')
      FileUtils.mv 'markdown', 'old_markdown_files'
    end
    attrs = case
            when polytex?  then yaml_attrs
            when markdown? then read_from_md
            else
              self.class.not_found!
            end.symbolize_keys!

    marshal_load attrs

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
      self.author = base_contents.scan(/^\s*\\author\{(.*?)\}/).flatten.first
      chapter_includes(base_contents).each_with_index do |name, i|
        slug = File.basename(name, '.*')
        title_regex = /^\s*\\chapter{(.*)}/
        content = File.read(File.join('chapters', slug + '.tex'))
        title = content[title_regex, 1]
        j = 0
        sections = content.scan(/^\s*\\section{(.*)}/).flatten.map do |name|
          Section.new(name: name, section_number: j += 1)
        end
        chapters.push Chapter.new(slug: slug,
                                  title: title,
                                  sections: sections,
                                  chapter_number: i + 1)
      end
    end
    # TODO: verify all attributes

    verify_paths! if options[:verify_paths]
  end

  def chapter_includes(string)
    chapter_regex = /^\s*\\include\{chapters\/(.*?)\}/
    string.scan(chapter_regex).flatten
  end

  # Removes frontmatter
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

  def markdown?
    (@source == :markdown || @source == :md) && !@force_polytex
  end
  alias :md? :markdown?

  def polytex?
    @source == :polytex || @force_polytex
  end

  def chapter_file_paths
    pdf_chapter_names.map do |name|
      file_path = case
      when markdown? then File.join("markdown", "#{name}.md")
      when polytex?  then File.join("chapters", "#{name}.tex")
      end

      yield file_path if block_given?

      file_path
    end
  end

  # Return chapters for the PDF.
  def pdf_chapter_names
    chaps = chapters.reject { |chapter| chapter.slug.match(/frontmatter/) }.
                     collect(&:slug)
    frontmatter? ? frontmatter + chaps : chaps
  end

  def find_chapter_by_slug(slug)
    chapters.find { |chapter| chapter.slug == slug }
  end

  def find_chapter_by_number(number)
    chapters.find { |chapter| chapter.chapter_number == number }
  end

  def url(chapter_number)
    if chapter = find_chapter_by_number(chapter_number)
      chapter.slug
    else
      '#'
    end
  end

  def self.valid_directory?
    [YAML_PATH, MD_PATH].any? { |f| File.exist?(f) }
  end

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

  private

    def read_from_yml
      require 'polytexnic/config'
      require 'yaml/store'
      self.class.find_book_root!
      YAML.load_file(YAML_PATH)
    end

    def read_from_md
      self.class.find_book_root!
      chapters = File.readlines(MD_PATH).select do |path|
                   path =~ /(.*)\.md/
                 end.map do |file|
                   Chapter.new(slug: File.basename(file.strip, '.md'))
                 end
      { chapters: chapters, filename: MD_PATH }
    end

    def verify_paths!
      chapter_file_paths do |chapter_path, i|
        next if chapter_path =~ /frontmatter/
        unless File.exist?(chapter_path)
          raise "Chapter file in manifest not found in #{chapter_path}"
        end
      end
    end
end