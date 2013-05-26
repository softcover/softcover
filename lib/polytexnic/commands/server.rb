require 'listen'

module Polytexnic::Commands::Server
  extend self

  def listen_for_changes
    server_pid = Process.pid
    fork do
      puts 'Listening for changes.'
      begin
        Listen.to!('.', 'chapters', filter: /(\.tex|\.md)$/) do
          rebuild
          Process.kill("USR2", server_pid)
        end
      rescue Interrupt
        puts 'Shutting down listener.'
      end
    end
  end

  def rebuild
    printf "Change detected, rebuilding... "
    t = Time.now
    Polytexnic::Builders::Html.new.build
    puts "Done. (#{(Time.now - t).round(2)}s)"
  end

  def start_server(port)
    rebuild
    Polytexnic::App.set :port, port
    Polytexnic::App.run!
  end

  def run(port)
    listen_for_changes
    start_server port
  end
end
