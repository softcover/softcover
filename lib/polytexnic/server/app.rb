require 'sinatra/base'
require 'sinatra/respond_to'
require 'sinatra/async'

class Polytexnic::App < Sinatra::Base
  register Sinatra::RespondTo
  register Sinatra::Async

  set :public_folder, File.join(File.dirname(__FILE__),'../template/html')
  set :bind, '0.0.0.0'

  before do
    @manifest = Polytexnic::BookManifest.new
  end

  get '/' do
    # redirect to first chapter
    redirect @manifest.chapters.first.slug
  end

  get '/refresh' do
    require 'coffee_script'
    @mathjax_src    = Polytexnic::Mathjax::AMS_HTML
    @mathjax_config = Polytexnic::Mathjax.config
    coffee erb :refresh
  end

  get '/stylesheets/pygments' do
    @pygments_css ||= Pygments.send(:mentos, :css, ['html', '']).
                               gsub!(/^/, '.highlight ')
  end

  # Gets the image specified by the path and content type.
  get '/images/*' do |path|
    extension  = response.header['Content-Type'].split('/').last
    # Arrange to handle both '.jpeg' and '.jpg' extensions.
    if extension == 'jpeg' && !File.exist?(image_filename(path, extension))
      extension = 'jpg'
    end
    file_path = image_filename(path, extension)
    File.exists?(file_path) ? File.read(file_path) : nil
  end

  # Returns the image filename for the local document.
  def image_filename(path, extension)
    "html/images/#{path}.#{extension}"
  end

  get '/:chapter_slug' do
    get_chapter
    doc = Nokogiri::HTML.fragment(File.read(@chapter.fragment_path))
    doc.css('a.hyperref').each do |node|
      node['href'] = node['href'].gsub(/_fragment\.html/, '')
    end
    @html = doc.to_xhtml

    respond_to do |format|
      format.js do
        content_type :html
        @html
      end
      format.html do
        @title = @chapter.title
        @local_server = true
        erb :book
      end
    end
  end

  aget '/:chapter_slug/wait' do
    require 'json'
    Signal.trap("SIGINT") { exit 0 }
    Signal.trap("HUP") do
      body({ time: Time.now }.to_json)
    end
  end

  not_found do
    '404'
  end

  def get_chapter
    if params[:chapter_slug]
      @chapter = @manifest.find_chapter_by_slug(params[:chapter_slug])
      raise Sinatra::NotFound unless @chapter
    end
  end
end