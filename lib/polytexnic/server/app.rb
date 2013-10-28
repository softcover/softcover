require 'sinatra/base'
require 'sinatra/respond_to'
require 'sinatra/async'

class Polytexnic::App < Sinatra::Base
  register Sinatra::Async

  set :public_folder, File.join(File.dirname(__FILE__),'../template/html')
  set :bind, '0.0.0.0'

  configure do
    mime_type :map, 'application/javascript'
  end

  before do
    @manifest = Polytexnic::BookManifest.new
  end

  get '/' do
    redirect @manifest.first_chapter.slug
  end

  get '/main.js' do
    require 'coffee_script'
    @mathjax_src    = Polytexnic::Mathjax::AMS_HTML
    @mathjax_config = Polytexnic::Mathjax.escaped_config
    coffee erb :'main.js'
  end

  get '/stylesheets/pygments.css' do
    content_type 'text/css'
    @pygments_css ||= Pygments.send(:mentos, :css, ['html', '']).
                               gsub!(/^/, '.highlight ')
  end

  # Gets the image specified by the path and content type.
  get '/images/*' do |path|
    split_path = path.split(/\./)
    extension = split_path.pop
    path = split_path * ''
    # Arrange to handle both '.jpeg' and '.jpg' extensions.
    if extension == 'jpeg' && !File.exist?(image_filename(path, extension))
      extension = 'jpg'
    end
    file_path = image_filename(path, extension)
    if File.exists?(file_path)
      content_type extension
      File.read(file_path)
    else
      raise Sinatra::NotFound
    end
  end

  get '/assets/:path' do
    extension = params[:path].split('.').last
    content_type extension
    File.read(File.join(File.dirname(__FILE__),'assets', params[:path]))
  end

  # Returns the image filename for the local document.
  def image_filename(path, extension)
    "html/images/#{path}.#{extension}"
  end

  get '/:chapter_slug.?:format?' do
    get_chapter
    doc = Nokogiri::HTML.fragment(File.read(@chapter.fragment_path))
    doc.css('a.hyperref').each do |node|
      node['href'] = node['href'].gsub(/_fragment\.html/, '')
    end
    @html = doc.to_xhtml

    if params[:format] == 'js'
      content_type :html
      @html
    else
      @title = @chapter.menu_heading
      @local_server = true
      erb :'book.html'
    end
  end

  aget '/:chapter_slug/wait' do
    require 'json'
    Signal.trap("SIGINT") { exit 0 }
    Signal.trap("HUP") do
      Thread.new { body({ time: Time.now }.to_json) }
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