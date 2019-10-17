#encoding: utf-8
require 'ostruct'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class Softcover::BookManifest < OpenStruct
  include Softcover::Utils

  attr_accessor :book_file

  class Softcover::MarketingManifest < Softcover::BookManifest

    YAML_PATH = File.join(Softcover::Directories::CONFIG, 'marketing.yml')
    def initialize
      marshal_load read_from_yml.symbolize_keys!
    end
  end

  def escaped_title
    CGI.escape_html(title)
  end

  # Run the title through the Polytexnic pipeline to make an HTML title.
  def html_title
    polytexnic_html(title)
  end

  class NotFound < StandardError
    def message
      "Invalid document directory, no manifest file found!"
    end
  end

  class Chapter < OpenStruct
    include Softcover::Utils

    def fragment_name
      "#{slug}_fragment.#{html_extension}"
    end

    def fragment_path
      File.join('html', fragment_name)
    end

    def nodes
      @nodes ||= []
    end

    # Returns a chapter heading for use in the navigation menu.
    def menu_heading
      raw_html = Polytexnic::Pipeline.new(title,
                                          language_labels: language_labels).
                                         to_html
      doc = Nokogiri::HTML(raw_html).at_css('p')
      # Handle case of a footnote in the chapter title.
      doc.css('sup').each do |footnote_node|
        footnote_node.remove
      end
      html = doc.inner_html
      if chapter_number.zero? || article? || chapter_number == 99999
        html
      else
        "#{chapter_label(chapter_number)}: #{html}"
      end
    end

    # Run the title through the Polytexnic pipeline to make an HTML title.
    def html_title
      self.polytexnic_html(title)
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

    # Returns the name for the cached version of the chapters.
    # This is used when processing Markdown to avoid unnecessary calls to
    # kramdown's to_latex method, which can get expensive.
    def cache_filename
      Softcover::Utils.path("tmp/#{full_name}.cache")
    end
  end

  class Section < OpenStruct
  end

  TXT_PATH  = 'Book.txt'
  YAML_PATH = File.join(Softcover::Directories::CONFIG, 'book.yml')

  def initialize(options = {})
    @source = options[:source] || :polytex
    @origin = options[:origin]
    @book_file = TXT_PATH

    ensure_template_files

    if ungenerated_markdown?
      puts "Error: No book to publish"
      puts "Run `softcover build:<format>` for at least one format"
      exit 1
    end

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
      self.backmatter = []
      base_contents = File.read(tex_filename)

      if base_contents.match(/frontmatter/)
        @frontmatter = true
        chapters.push Chapter.new(slug:  'frontmatter',
                                  title: language_labels["frontmatter"],
                                  sections: nil,
                                  chapter_number: 0)
      end

      if base_contents.match(/backmatter/)
        @backmatter = true
      end

      raw_frontmatter = remove_frontmatter(base_contents, frontmatter)
      raw_backmatter = remove_backmatter(base_contents, backmatter)

      if frontmatter?
        self.frontmatter = chapter_includes(raw_frontmatter)
      else
        self.frontmatter = []
      end
      if backmatter?
        self.backmatter = chapter_includes(raw_backmatter)
      else
        self.backmatter = []
      end

      chapter_includes(base_contents).each_with_index do |name, i|
        slug = File.basename(name, '.*')
        chapter_title_regex = /^\s*\\chapter{(.*)}/
        filename = File.join(polytex_dir, slug + '.tex')
        content = File.read(filename)
        chapter_title = content[chapter_title_regex, 1]
        if article? && @origin == :markdown
          if chapter_title.nil?
            # Articles are "chapters" with the title of the full document.
            chapter_title = title
          else
            # Override the title based on the value of the top-level heading.
            self.title = chapter_title
            # Overwrite book.yml with the new title.
            book_yml = File.read(YAML_PATH)
            File.write(YAML_PATH, book_yml.sub(/title: .*/, "title: #{title}"))
            # Strip out the chapter line, which is invalid in articles.
            File.write(filename, content.sub(chapter_title_regex, ''))
          end
        end
        j = 0
        sections = content.scan(/^\s*\\section{(.*)}/).flatten.map do |name|
          Section.new(name: name, section_number: j += 1)
        end
        chapter_title = title if article?
        chapters.push Chapter.new(slug: slug,
                                  title: chapter_title,
                                  sections: sections,
                                  chapter_number: i + 1)
      end
      
      if backmatter?
        chapters.push Chapter.new(slug:  'backmatter',
                                  title: language_labels["backmatter"],
                                  sections: nil,
                                  chapter_number: 99999)
      end
    end
    write_master_latex_file(self)
    verify_paths! if options[:verify_paths]
  end

  # Ensures the existence of needed template files like 'marketing.yml'.
  # We copy from the template if necessary.
  # Needed for backwards compatibility.
  def ensure_template_files
    self.class.find_book_root!
    template_dir = Softcover::Utils.template_dir(article:
                                                 Softcover::Utils.article?)
    files = [File.join(Softcover::Directories::CONFIG, 'marketing.yml'),
             path('images/cover-web.png'),
             path('latex_styles/custom_pdf.sty'),
             path('latex_styles/applekeys.sty'),
             path('config/preamble.tex'),
             path('config/lang.yml'),
             path('epub/OEBPS/styles/custom_epub.css'),
             path('epub/OEBPS/styles/page-template.xpgt'),
           ]
    files.each do |file|
      unless File.exist?(file)
        puts "Copying missing file '#{file}' from template"
        FileUtils.mkdir_p(File.dirname(file))
        FileUtils.cp(File.join(template_dir, file), file)
      end
    end
  end

  # Handles case of Markdown books without running `softcover build`.
  def ungenerated_markdown?
    dir = 'generated_polytex'
    @origin == :markdown && (!File.directory?(dir) ||
                             Dir.glob(path("#{dir}/*")).empty?)
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

  # Removes backmatter
  def remove_backmatter(base_contents, backmatter)
    base_contents.gsub!(/\\backmatter(.*)\\end{document}/m, '')
    $1
  end

  # Returns true if the book has frontmatter.
  def frontmatter?
    @frontmatter
  end

  # Returns true if the book has a backmatter.
  def backmatter?
    @backmatter
  end

  # Returns the first full chapter.
  # This arranges to skip the frontmatter, if any.
  def first_chapter
    frontmatter? ? chapters[1] : chapters[0]
  end

  # Returns the last chapter
  def last_chapter
    chapters[-1]
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

  # Returns the name of the HTML file containing the full book.
  def full_html_file
    path("html/#{slug}.#{html_extension}")
  end

  # Returns chapters for the PDF.
  def pdf_chapter_names
    chaps = chapters.reject { |chapter| chapter.slug == 'frontmatter' || chapter.slug == 'backmatter' }.
                     collect(&:slug)
    if frontmatter
      chaps = frontmatter + chaps
    end
    if backmatter
      chaps = chaps + backmatter
    end
    chaps
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
    unless respond_to?(:epub_mobi_preview_chapter_range)
      $stderr.puts("Error: Preview not built")
      $stderr.puts("Define epub_mobi_preview_chapter_range in config/book.yml")
      $stderr.puts("See http://manual.softcover.io/book/getting_started#sec-build_preview")
      exit(1)
    end

    first, last = epub_mobi_preview_chapter_range.split('..').map(&:to_i)
    first..last
  end

  # Returns the chapters to use in the preview as a range.
  def preview_chapters
    chapters[preview_chapter_range]
  end

  def self.valid_directory?
    # Needed for backwards compatibility
    if File.exist?('book.yml') && !Dir.pwd.include?('config')
      Softcover::Utils.mkdir('config')
      FileUtils.mv('book.yml', 'config')
    end
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
    book_file_lines(self).select { |path| path =~ md_tex }.map(&:strip)
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
    { chapters: chapter_objects, filename: book_file }
  end


  private

    def read_from_yml
      require 'softcover/config'
      require 'yaml/store'
      self.class.find_book_root!
      ensure_book_yml
      YAML.load_file(self.class::YAML_PATH)
    end

    # Ensures that the book.yml file is in the right directory.
    # This is for backwards compatibility.
    def ensure_book_yml
      path = self.class::YAML_PATH
      unless File.exist?(path)
        base = File.basename(path)
        Softcover::Utils.mkdir Softcover::Directories::CONFIG
        FileUtils.mv base, Softcover::Directories::CONFIG
      end
    end


    def verify_paths!
      chapter_file_paths do |chapter_path|
        next if chapter_path =~ /(front|back)matter/

        unless File.exist?(chapter_path)
          $stderr.puts "ERROR -- document not built"
          $stderr.puts "Chapter file '#{chapter_path}'' not found"
          exit 1
        end
      end
    end
end
