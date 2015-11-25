require 'listen'

module Softcover::Commands::Server
  include Softcover::Output
  include Softcover::Utils
  attr_accessor :no_listener
  extend self

  # Listens for changes to the book's source files.
  def listen_for_changes
    return if defined?(@no_listener) && @no_listener
    server_pid = Process.pid
    filter_regex = /(\.md|\.tex|custom\.sty|custom\.css|Book\.txt|book\.yml)$/
    @listener = Listen.to('.')
    @listener.filter(filter_regex)

    @listener.change do |modified|
      first_modified = modified.try(:first)
      unless first_modified =~ ignore_regex
        rebuild first_modified
        Process.kill("HUP", server_pid)
      end
    end
    @listener.start
  end

  # Returns a regex for files to be ignored by the listener.
  def ignore_regex
    ignores = ['generated_polytex', '\.tmp\.tex']
    # Ignore <book>.tex, which gets overwritten each time PolyTeXnic runs,
    # unless there's no Book.txt, which means the author is using raw LaTeX.
    if File.exist?(Softcover::BookManifest::TXT_PATH)
      ignores << Regexp.escape(Dir.glob('*.tex').first)
    end
    /(#{ignores.join('|')})/
  end

  def markdown?
    !Dir.glob(path('chapters/*.md')).empty?
  end

  def rebuild(modified=nil)
    printf modified ? "=> #{File.basename modified} changed, rebuilding... " :
                      'Building...'
    t = Time.now
    builder = Softcover::Builders::Html.new
    builder.build
    puts "Done. (#{(Time.now - t).round(2)}s)"

  rescue Softcover::BookManifest::NotFound => e
    puts e.message
  end

  def start_server(port, bind)
    require 'softcover/server/app'
    puts "Running Softcover server on http://#{bind}:#{port}"
    Softcover::App.set :port, port
    Softcover::App.set :bind, bind
    Softcover::App.run!
  end

  def run(port, bind)
    rebuild
    listen_for_changes
    start_server port, bind
  end
end
