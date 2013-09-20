require 'listen'

module Polytexnic::Commands::Server
  include Polytexnic::Output
  attr_accessor :no_listener
  extend self

  def listen_for_changes
    return if defined?(@no_listener) && @no_listener
    server_pid = Process.pid
    @listener = Listen.to('chapters')
    @listener.filter(/(\.tex|\.md)$/)
    @listener.ignore(%r{^.tmp})
    @listener.change do |modified|
      rebuild modified.try(:first)
      Process.kill("HUP", server_pid)
    end
    @listener.start
  end

  def rebuild(modified=nil)
    printf modified ? "=> #{File.basename modified} changed, rebuilding... " :
                      'Building...'
    t = Time.now
    Polytexnic::Builders::Html.new.build
    puts "Done. (#{(Time.now - t).round(2)}s)"

  rescue Polytexnic::BookManifest::NotFound => e
    puts e.message
  end

  def start_server(port)
    require 'polytexnic/server/app'
    rebuild
    puts "Running Polytexnic server on http://localhost:#{port}"
    Polytexnic::App.set :port, port
    Polytexnic::App.run!
  end

  def run(port)
    listen_for_changes
    start_server port
  end
end
