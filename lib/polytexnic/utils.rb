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

end

