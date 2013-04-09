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
    files = Dir['**/*']

    is_book_directory = true

    Polytexnic::FORMATS.each do |format|
      unless files.any?{|file| File.extname(file) == ".#{format}"}
        puts "No #{format} found."
        is_book_directory = false
      end
    end
    return is_book_directory
  end

  def logged_in?
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
    filename.sub('.tex', '.tmp.tex')
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

end

