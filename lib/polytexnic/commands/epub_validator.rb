module Polytexnic
  module Commands
    module EpubValidator
      extend self

      # Validates a book according to the EPUB standard.
      def validate!
        book = Polytexnic::Book.new
        book.validate_epub
      end
    end
  end
end
