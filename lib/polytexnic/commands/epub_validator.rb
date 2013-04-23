module Polytexnic
  module Commands
    module EpubValidator
      extend self

      def validate!
        book = Polytexnic::Book.new
        book.validate
      end

    end
  end
end
