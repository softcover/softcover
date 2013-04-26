require 'rack'
require 'listen'

module Polytexnic::Commands::Server
  extend self

  def listen_for_changes
    Thread.new do
      puts 'Listening for changes.'
      Listen.to!('.', 'chapters', filter: /(\.tex|\.md)$/) do
        rebuild
      end
    end
  end

  def rebuild
    printf "Change detected, rebuilding... "
    t = Time.now
    Polytexnic::Builders::Html.new.build
    puts "Done. (#{(Time.now - t).round(2)}s)"
  end

  def handler
    Rack::Handler::Thin
  end

  def start_server(port)
    rebuild

    app = Rack::Builder.new do
      use Rack::Static, urls: ['/'], root: 'html'
      run lambda { [200, {}, ['']] }
    end

    handler.run(app, :Port => port)
  end

  def run(port)
    listen_for_changes
    start_server port
  end
end
