require 'sinatra/base'
require 'sinatra/respond_to'
require 'coffee_script'

class Polytexnic::App < Sinatra::Base
  register Sinatra::RespondTo

  set :public_folder, File.join(File.dirname(__FILE__),'../template/html')

  before do
    @manifest = Polytexnic::BookManifest.new
  end

  get '/' do
    # redirect to first chapter
    redirect @manifest.chapters.first.slug
  end

  get '/refresh' do
    coffee :refresh
  end

  get '/stylesheets/pygments' do
    @pygments_css ||= Pygments.send(:mentos, :css, ['html', '']).
                               gsub!(/^/, '.highlight ')
  end

  get '/:chapter_slug' do
    get_chapter
    doc = Nokogiri::HTML.fragment(File.read(@chapter.fragment_path))
    doc.css('a.hyperref').each do |node|
      node['href'] = node['href'].gsub(/_fragment\.html/, '')
    end
    @html = doc.to_html

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

  get '/:chapter_slug/wait' do
    $changed = false
    Signal.trap("USR2") do
      $changed = true
    end
    loop do
      sleep 0.1
      break if $changed
    end
    { time: Time.now }.to_json
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