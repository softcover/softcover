module Polytexnic
  module Commands
    module Auth
      extend self

      def login(email, password)
        client = Polytexnic::Client.new email, password
        client.login!
      end

      def logout
        Polytexnic::Config['api_key'] = nil
      end
    end
  end
end
