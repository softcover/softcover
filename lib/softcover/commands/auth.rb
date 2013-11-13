module Softcover
  module Commands
    module Auth
      extend self

      def login(email, password)
        require "softcover/client"
        client = Softcover::Client.new email, password
        client.login!
      end

      def logout
        require "softcover/config"
        Softcover::Config['api_key'] = nil
      end
    end
  end
end
