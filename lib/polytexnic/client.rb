require 'rest_client'
require 'json'

module Polytexnic
  class Client
    include Polytexnic::Utils

    ApiVerion = 1

    ApiPrefix = "/api/v#{ApiVerion}"

    Paths = {
      login: 'login',
      books: 'books'
    }

    def initialize(email=nil,password=nil)
      @email = email
      @password = password

      @api_key = Polytexnic::Config['api_key']
      @host = Polytexnic::Config['host']
    end

    # ============ Auth ===========
    def login!
      begin
        response = post path_for(:login), 
          email: @email, password: @password

      rescue RestClient::UnprocessableEntity
        Polytexnic::Config['api_key'] = nil
        return false
      end

      json = JSON response
      Polytexnic::Config['api_key'] = @api_key = json['api_key']
    end

    # ============ Publishing ===========
    def create_book(files)
      JSON post path_for(:books), files: files
    end

    def notify_upload_complete(book_id)
      JSON put path_for(:books, book_id), upload_complete: true
    end

    private
      %w{get put post}.each do |verb|
        define_method verb do |url, params, headers={}|
          RestClient.post "#{@host}#{url}", 
            params_with_key(params).to_json, 
            formatted_headers(headers)
        end
      end

      def params_with_key(params)
        @api_key.present? ? params.merge({api_key: @api_key}) : params
      end

      def formatted_headers(headers={})
        headers.merge accept: :json, content_type: :json
      end

      def path_for(action, *args)
        File.join ApiPrefix, Paths[action], *(args.map &:to_s)
      end
  end
end