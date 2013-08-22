module Polytexnic
  module Commands
    module EpubValidator
      extend self

      def validate!
        book = Polytexnic::Book.new
        book.validate_epub
      end
    end
  end
end
