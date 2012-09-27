require 'rest_client'
require 'json'

module Polytexnic
  class Client
    def initialize(email=nil,password=nil)
      @email = email
      @password = password

      @api_key = Polytexnic::Config['api_key']
      @host = Polytexnic::Config['host']
    end

    def login!
      begin
        response = post '/login', email: @email, password: @password

      rescue RestClient::UnprocessableEntity
        Polytexnic::Config['api_key'] = nil
        return false
      end

      Polytexnic::Config['api_key'] = @api_key = response[:api_key]
    end

    private
      def post(url, params, headers={})
        headers.merge! accept:'json', content_type: 'application/json'
        params.merge! api_key: @api_key if @api_key.present?

        RestClient.post @host+url, params, headers
      end
  end
end