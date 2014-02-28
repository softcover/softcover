
module Softcover
  class Client
    include Softcover::Utils

    ApiVersion = 1

    ApiPrefix = "/api/v#{ApiVersion}"

    Paths = {
      login: 'login',
      books: 'books'
    }

    attr_accessor :host, :book

    def initialize(email=nil,password=nil,book=nil)
      require 'json'
      require 'rest_client'
      require "softcover/config"
      @email = email
      @password = password
      @book = book

      @api_key = Softcover::Config['api_key']
      @host = Softcover::Config['host']
    end

    def self.new_with_book(book)
      new nil, nil, book
    end

    # ============ Auth ===========
    def login!
      require "softcover/config"
      response = post path_for(:login), email: @email, password: @password

      json = JSON response
      Softcover::Config['api_key'] = @api_key = json['api_key']
    end

    # ============ Publishing ===========
    def create_or_update_book(params)
      JSON post path_for(:books), params
    rescue RestClient::ResourceNotFound
      { "errors" =>
        "Book ID #{params[:id]} not found for this account. "+
        "Either login again or delete this file: .softcover-book"
      }
    end

    def notify_file_upload(params)
      JSON post path_for(:books, book.id, :notify_file_upload), params
    end

    def notify_upload_complete
      JSON put path_for(:books, book.id), upload_complete: true
    end

    def destroy
      delete path_for(:books, book.id)
    end

    def destroy_book_by_slug(slug)
      delete path_for(:books, slug)
    end

    # ============ Screencasts ===========
    def get_screencast_upload_params(files)
      JSON post path_for(:books, book.id, :screencasts), files: files
      # TODO: handle errors
    end

    # ============ Utils ===========
    private
      %w{put post}.each do |verb|
        define_method verb do |url, params={}, headers={}|
          begin
            RestClient.send verb, @host + url,
              params_with_key(params).to_json,
              formatted_headers(headers)
          rescue RestClient::UnprocessableEntity
            handle_422
          end
        end
      end

      %w{get delete}.each do |verb|
        define_method verb do |url, headers={}|
          begin
            path = "#{@host + url}?api_key=#{@api_key}"
            RestClient.send verb, path, formatted_headers(headers)
          rescue RestClient::UnprocessableEntity
            handle_422
          end
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
        return { "errors" => "You don't have access to that resource." }
      end
  end
end