module Softcover
  module Commands
    module Opener
      extend self

      def open!
        book.open_in_browser
      end

      # Returns the book to be opened.
      def book
        Softcover::Book.new(origin: Softcover::Utils::source)
      end

    end
  end
end
