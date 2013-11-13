module Polytexnic::Utils
  extend self

  def current_book
    # using module level variable because it should be context independent
    @@current_book ||= begin
      in_book_directory? ? Polytexnic::Book.new : false
    end
  end

  def reset_current_book!
    @@current_book = nil
  end

  def in_book_directory?
    Polytexnic::BookManifest::find_book_root!

    files = Dir['**/*']

    Polytexnic::FORMATS.each do |format|
      unless files.any?{ |file| File.extname(file) == ".#{format}" }
        puts "No #{format} found, skipping."
      end
    end

    return Polytexnic::BookManifest::valid_directory?
  end

  def logged_in?
    require 'polytexnic/config'
    Polytexnic::Config['api_key'].present?
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

  # Returns the tmp version of a filename.
  # E.g., tmpify('foo.tex') => 'foo.tmp.tex'
  def tmpify(filename)
    sep = File::SEPARATOR
    filename.sub('chapters' + sep, 'tmp' + sep).sub('.tex', '.tmp.tex')
  end

  # Writes a Pygments style file.
  # We support both :html (outputting CSS) and :latex (outputting
  # a LaTeX style file).
  def write_pygments_file(format, path = '.')
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
  def executable(filename, message)
    filename.tap do |f|
      unless File.exist?(f)
        $stderr.puts message
        exit 1
      end
    end
  end

  def mkdir(dir)
    Dir.mkdir(dir) unless File.directory?(dir)
  end

  def rm(file)
    FileUtils.rm(file) if File.exist?(file)
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
    Polytexnic.test? ? system(command) : exec(command)
  end

  def silence
    return yield if ENV['silence'] == 'false'

    silence_stream(STDOUT) do
      yield
    end
  end
end

