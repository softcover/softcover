module Softcover
  module Commands
    module Opener
      extend self

      def open!
        book = Softcover::Book.new(origin: Softcover::Utils::source)
        book.open_in_browser
      end

    end
  end
end
