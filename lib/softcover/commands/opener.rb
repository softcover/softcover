module Softcover
  module Commands
    module Opener
      extend self

      def open!
        book = Softcover::Book.new
        book.open_in_browser
      end

    end
  end
end
