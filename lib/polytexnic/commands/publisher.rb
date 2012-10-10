require 'ruby-progressbar'
require 'curb'

module Polytexnic::Commands::Publisher
  include Polytexnic::Utils

  extend self

  def publish!
    return false unless in_book_directory?

    book = Polytexnic::Book.new

    puts "Getting upload signatures..."
    if book.create
      puts "Uploading #{book.files.count} files (#{as_size book.total_size}):"
      book.upload!
    else
      puts book.errors
      raise 'Could not get upload signature.'
    end
    
    true
  end
end
