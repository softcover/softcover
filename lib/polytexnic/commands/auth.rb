module Polytexnic
  module Commands
    module Auth
      extend self

      def login(email, password)
        require "polytexnic/client"
        client = Polytexnic::Client.new email, password
        client.login!
      end

      def logout
        require "polytexnic/config"
        Polytexnic::Config['api_key'] = nil
      end
    end
  end
end
