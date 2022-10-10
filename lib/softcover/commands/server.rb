require 'listen'

module Softcover::Commands::Server
  include Softcover::Output
  include Softcover::Utils
  attr_accessor :no_listener
  extend self

  # Listens for changes to the book's source files.
  def listen_for_changes(fmt="html", overfull=false)
    return if defined?(@no_listener) && @no_listener
    server_pid = Process.pid
    filter_regex = /(\.md|\.tex|custom\.sty|custom\.css|Book\.txt|book\.yml)$/
    @listener = Listen.to('.', only: filter_regex, ignore: /html\//) do |modified|
      first_modified = modified.try(:first)
      unless first_modified =~ ignore_regex
        rebuild(fmt, modified: first_modified, overfull: overfull)
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

  def rebuild(fmt, modified: nil, overfull: nil)
    printf modified ? "=> #{File.basename modified} changed, rebuilding... " :
                      'Building...'
    t = Time.now

    if fmt == "html"
      builder = Softcover::Builders::Html.new
      builder.build
    elsif fmt == "pdf"
      if overfull
        options = "--find-overfull"
      else
        options = "--once --nonstop --quiet"
      end
      system "softcover build:pdf #{options}"
    else
      raise ArgumentError, "Unrecognized format #{fmt}"
    end
    puts "Done. (#{(Time.now - t).round(2)}s)"

  rescue Softcover::BookManifest::NotFound => e
    puts e.message
  end

  def start_server(port, bind, fmt)
    require 'softcover/server/app'
    if fmt == "html"
      puts "Running Softcover server on http://#{bind}:#{port}"
      Softcover::App.set :port, port
      Softcover::App.set :bind, bind
    end
    Softcover::App.run!
  end

  def run(port, bind, fmt, overfull)
    rebuild(fmt, overfull: overfull)
    listen_for_changes(fmt, overfull)
    start_server port, bind, fmt
  end
end

# Listen >=2.8 patch to silence duplicate directory errors. USE AT YOUR OWN RISK
require 'listen/record/symlink_detector'
module Listen
  class Record
    class SymlinkDetector
      def _fail(_, _)
        fail Error, "Don't watch locally-symlinked directory twice"
      end
    end
  end
end
