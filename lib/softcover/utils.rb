module Softcover::Utils
  extend self

  def current_book
    # using module level variable because it should be context independent
    @@current_book ||= begin
      in_book_directory? ? Softcover::Book.new(origin: source) : false
    end
  end

  # Returns the source type (PolyTeX or Markdown) of the current book.
  def source
    Dir.glob(path('chapters/*.md')).empty? ? :polytex : :markdown
  end

  # Returns the slug to be unpublished.
  def unpublish_slug
    Softcover::BookManifest.new(origin: source).slug
  end

  def reset_current_book!
    @@current_book = nil
  end

  def in_book_directory?
    Softcover::BookManifest::find_book_root!

    files = Dir['**/*']

    Softcover::FORMATS.each do |format|
      unless files.any?{ |file| File.extname(file) == ".#{format}" }
        puts "No #{format} found, skipping."
      end
    end

    return Softcover::BookManifest::valid_directory?
  end

  def logged_in?
    require 'softcover/config'
    Softcover::Config['api_key'].present?
  end

  UNITS = %W(B KB MB GB TB).freeze

  def as_size(number)
    if number.to_i < 1024
      exponent = 0

    else
      max_exp  = UNITS.size - 1

      exponent = ( Math.log( number ) / Math.log( 1024 ) ).to_i
      exponent = max_exp if exponent > max_exp

      number  /= 1024 ** exponent
    end

    "#{number.round} #{UNITS[ exponent ]}"
  end


  # Writes the master LaTeX file <name>.tex to use chapters from Book.txt.
  # We skip this step if Book.txt doesn't exist, as that means the user
  # is writing raw LaTeX.
  def write_master_latex_file(manifest)
    if File.exist?(manifest.book_file)
      File.write(master_filename(manifest), master_content(manifest))
    end
  end

  # Returns the name of the master LaTeX file.
  def master_filename(manifest)
    "#{manifest.filename}.tex"
  end

  # Returns the lines of book file as an array, removing commented-out lines.
  def book_file_lines(manifest)
    non_comment_lines(raw_lines(manifest))
  end

  # Returns only non-comment lines.
  def non_comment_lines(lines)
    comment = /^\s*#.*$/
    lines.reject { |line| line.match(comment) }
  end

  # Returns all the lines in Book.txt.
  def raw_lines(manifest)
    File.readlines(manifest.book_file)
  end

  # Returns the content for the master LaTeX file.
  def master_content(manifest)
    front_or_mainmatter = /(.*):\s*$/
    source_file = /(.*)(?:\.md|\.tex)\s*$/

    tex_file = [master_latex_header(manifest)]
    book_file_lines(manifest).each do |line|
      if line.match(source_file)
        tex_file << "\\include{#{manifest.polytex_dir}/#{$1}}"
      elsif line.match(front_or_mainmatter)  # frontmatter or mainmatter
        tex_file << "\\#{$1}"
      elsif line.strip == 'cover'
        tex_file << '\\includepdf{images/cover.pdf}'
      else # raw command, like 'maketitle' or 'tableofcontents'
        tex_file << "\\#{line.strip}"
      end
    end
    tex_file << '\end{document}'
    tex_file.join("\n") + "\n"
  end

  def master_latex_header(manifest)
    preamble = File.read(path('config/preamble.tex'))
    subtitle = manifest.subtitle.nil? ? "" : "\\subtitle{#{manifest.subtitle}}"
    <<-EOS
#{preamble}
\\usepackage{#{Softcover::Directories::STYLES}/softcover}
\\VerbatimFootnotes % Allows verbatim text in footnotes
\\title{#{manifest.title}}
#{subtitle}
\\author{#{manifest.author}}
\\date{#{manifest.date}}

\\begin{document}
    EOS
  end

  # Returns the tmp version of a filename.
  # E.g., tmpify('foo.tex') => 'foo.tmp.tex'
  def tmpify(manifest, filename)
    tmp = Softcover::Directories::TMP
    mkdir tmp
    sep = File::SEPARATOR
    filename.sub(manifest.polytex_dir + sep, tmp + sep).
             sub('.tex', '.tmp.tex')
  end

  # Writes a Pygments style file.
  # We support both :html (outputting CSS) and :latex (outputting
  # a LaTeX style file).
  def write_pygments_file(format, path)
    require 'pygments'
    extension = case format
                when :html
                  'css'
                when :latex
                  'sty'
                end
    # Here we burrow into the private 'Pygments#mentos' method.
    # Pygments exposes a 'css' method to return the CSS,
    # but we want to be able to output a LaTeX style file as well.
    # The inclusion of the ':css' symbol is necessary but doesn't actually
    # result in CSS being output unless the format is 'html'.
    pygments = Pygments.send(:mentos, :css, [format.to_s, ''])
    add_highlight_class!(pygments) if format == :html
    File.open(File.join(path, "pygments.#{extension}"), 'w') do |f|
      f.write(pygments)
    end
  end

  # Adds a 'highlight' class for MathJax compatibility.
  def add_highlight_class!(pygments_css)
    pygments_css.gsub!(/^/, '.highlight ')
  end

  # Returns a digest of the string.
  def digest(string)
    Digest::SHA1.hexdigest(string)
  end

  # Returns the executable if it exists, raising an error otherwise.
  def executable(filename)
    filename.tap do |f|
      unless File.exist?(f)
        $stderr.puts "Document not built due to missing dependency"
        $stderr.puts "Run `softcover check` to check dependencies"
        exit 1
      end
    end
  end

  def mkdir(dir)
    Dir.mkdir(dir) unless File.directory?(dir)
  end

  # Removes a file (or list of files).
  def rm(file)
    if file.is_a?(Array)
      file.each { |f| rm(f) }
    else
      FileUtils.rm(file) if File.exist?(file)
    end
  end

  # Returns the system-independent file path.
  # It's nicer to write `path('foo/bar/baz')` than
  # `File.join('foo', 'bar', 'baz')`.
  def path(path_string)
    File.join(*path_string.split('/'))
  end

  # Execute a command.
  # The issue here is that `exec` is awful in tests, since it exits the process.
  # This command arranges to use `system` in tests instead.
  def execute(command)
    Softcover.test? ? system(command) : exec(command)
  end

  def silence
    return yield if ENV['silence'] == 'false'

    silence_stream(STDOUT) do
      yield
    end
  end

  # Returns true if platform is OS X.
  def os_x?
    RUBY_PLATFORM.match(/darwin/)
  end

  # Returns true if platform is Linux.
  def linux?
    RUBY_PLATFORM.match(/linux/)
  end

  # Returns the commands from the given lines.
  # We skip comments and blank lines.
  def commands(lines)
    skip = /(^\s*#|^\s*$)/
    lines.reject { |line| line =~ skip }.join("\n")
  end

  # Returns the filename of a dependency given a label.
  def dependency_filename(label)
    case label
    when :latex
      `which xelatex`.chomp
    when :ghostscript
      `which gs`.chomp
    when :convert
      `which convert`.chomp
    when :node
      `which node`.chomp
    when :phantomjs
      `which phantomjs`.chomp
    when :kindlegen
      `which kindlegen`.chomp
    when :java
      `which java`.chomp
    when :calibre
      `which ebook-convert`.chomp
    when :epubcheck
      File.join(Dir.home, 'epubcheck-3.0', 'epubcheck-3.0.jar')
    when :inkscape
      filename = `which inkscape`.chomp
      if filename.empty?
        filename = '/Applications/Inkscape.app/Contents/Resources/bin/' +
                   'inkscape'
      end
      filename
    else
      raise "Unknown label #{label}"
    end
  end

  # Returns the language labels from the config file.
  def language_labels
    YAML.load_file(File.join(Softcover::Directories::CONFIG, 'lang.yml'))
  end

  def chapter_label(chapter_number)
    if language_labels["chapter"]["order"] == "reverse"
      "#{chapter_number} #{language_labels['chapter']['word']}"
    else
      "#{language_labels['chapter']['word']} #{chapter_number}"
    end
  end

end
