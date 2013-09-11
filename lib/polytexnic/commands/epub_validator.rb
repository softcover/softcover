module Polytexnic
  module Commands
    module EpubValidator
      extend self

      def validate!
        book = Polytexnic::Book.new
        book.epubcheck
      end
    end
  end
end
