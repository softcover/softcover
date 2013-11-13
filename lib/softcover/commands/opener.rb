module Polytexnic
  module Commands
    module Opener
      extend self

      def open!
        book = Polytexnic::Book.new
        book.open_in_browser
      end

    end
  end
end
