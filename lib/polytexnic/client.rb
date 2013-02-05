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
    
    attr_accessor :host, :book

    def initialize(email=nil,password=nil,book=nil)
      @email = email
      @password = password
      @book = book

      @api_key = Polytexnic::Config['api_key']
      @host = Polytexnic::Config['host']
    end

    def self.new_with_book(book)
      new nil, nil, book
    end

    # ============ Auth ===========
    def login!
      begin
        response = post path_for(:login), 
          email: @email, password: @password

      rescue RestClient::UnprocessableEntity
        return handle_422
      end

      json = JSON response
      Polytexnic::Config['api_key'] = @api_key = json['api_key']
    end

    # ============ Publishing ===========
    def create_or_update_book(params)
      JSON post path_for(:books), params
    rescue RestClient::UnprocessableEntity
      handle_422
    rescue RestClient::ResourceNotFound
      { "errors" => 
        "Book ID #{params[:id]} not found for this account. "+
        "Either login again or delete this file: .polytexnic-book" 
      }
    end

    def notify_file_upload(params)
      JSON post path_for(:books, book.id, :notify_file_upload), params
    end

    def notify_upload_complete
      JSON put path_for(:books, book.id), upload_complete: true
    end

    # ============ Screencasts ===========
    def get_screencast_upload_params(path)
      JSON post path_for(:books, book.id, :screencasts), path
    end

    # ============ Utils ===========
    private
      %w{get put post}.each do |verb|
        define_method verb do |url, params, headers={}|
          RestClient.send verb, "#{@host}#{url}", 
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

      def handle_422
        Polytexnic::Config['api_key'] = nil
        return false
      end
  end
end