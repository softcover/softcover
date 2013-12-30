require 'spec_helper'
require 'rack/test'

describe Softcover::App do
  include Rack::Test::Methods

  def app
    Softcover::App
  end

  context "ordinary book" do
    before(:all) do
      generate_book
      Softcover::Builders::Html.new.build!
    end
    # after(:all)  { remove_book }

    before { chdir_to_book }

    let(:manifest) { Softcover::BookManifest.new }
    let(:chapter) { manifest.chapters[1] }

    it 'redirects / to first chapter' do
      get '/'
      expect(last_response).to be_redirect
      expect(last_response.location).to match chapter.slug
    end

    it 'GET chapter' do
      get "/#{chapter.slug}"
      expect(last_response).to be_ok
      expect(last_response.body).to match Regexp.new(chapter.title)
    end

    it 'GET chapter.js' do
      get "/#{chapter.slug}.js"
      expect(last_response).to be_ok
      expect(last_response.body).to match Regexp.new(chapter.title)
      expect(last_response.body).not_to match Regexp.new('<html>')
    end

    it 'GET nonexistent chapter' do
      get '/boom'
      expect(last_response.status).to eq 404
    end

    describe 'serving files' do

      it 'GET pygments.css' do
        get '/stylesheets/pygments.css'
        expect_server_response_of_type 'text/css'
      end

      it 'GET softcover.css' do
        get '/stylesheets/softcover.css'
        expect_server_response_of_type 'text/css'
      end

      it 'GET custom.css' do
        get '/stylesheets/custom.css'
        expect_server_response_of_type 'text/css'
      end

      it 'GET main.js' do
        get '/main.js'
        expect_server_response_of_type 'application/javascript'
      end

      it 'GET css asset' do
        get '/assets/main.css'
        expect_server_response_of_type 'text/css'
      end

      it 'GET image asset' do
        get '/assets/icons.png'
        expect_server_response_of_type 'image/png'
      end

      it 'GET image within book' do
        get '/images/2011_michael_hartl.png'
        expect_server_response_of_type 'image/png'
      end

      def expect_server_response_of_type(type)
        expect(last_response).to be_ok
        expect(last_response.content_type).to match type
        expect(last_response.content_length > 0).to be_true
      end
    end
  end
end