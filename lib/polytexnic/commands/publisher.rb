require 'ruby-progressbar'
require 'curb'

module Polytexnic::Commands::Publisher
  include Polytexnic::Utils

  extend self

  def publish!
    return false unless in_book_directory?

    book = Polytexnic::Book.new

    if book.create_or_update
      puts "Uploading #{book.upload_params.count} files " \
        "(#{as_size book.total_upload_size}):"

      book.upload!
    else
      puts "Errors: #{book.errors}"
      return false
    end
    
    true
  end
end
