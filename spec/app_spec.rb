require 'spec_helper'
require 'rack/test'

describe Polytexnic::App do
  include Rack::Test::Methods

  before(:all) { generate_book }
  after(:all)  { remove_book }
  before { chdir_to_book }
  before { Polytexnic::Builders::Html.new.build! }

  let(:manifest) { Polytexnic::BookManifest.new }
  let(:chapter) { manifest.chapters.first }

  def app
    Polytexnic::App
  end

  it 'redirects / to first chapter' do
    get '/'
    expect(last_response).to be_redirect
    expect(last_response.location).to match manifest.chapters.first.slug
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

  it 'GET non existant chapter' do
    get '/boom'
    expect(last_response.status).to eq 404
  end

  it 'GET pygments.css' do
    get '/stylesheets/pygments.css'
    expect(last_response).to be_ok
  end

  it 'GET refresh.js' do
    get '/refresh.js'
    expect(last_response).to be_ok
  end

end