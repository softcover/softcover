require 'listen'

module Polytexnic::Commands::Server
  extend self

  def listen_for_changes
    server_pid = Process.pid
    listener_pid = fork do
      puts 'Listening for changes...'
      begin
        Listen.to!('.', 'chapters', filter: /[^.tmp](\.tex|\.md)$/) do |modified|
          rebuild modified.first
          Process.kill("HUP", server_pid)
        end
      rescue Interrupt
        puts 'Shutting down Polytexnic server and listener.'
      end
    end
    Process.detach listener_pid
  end

  def rebuild(modified=nil)
    printf modified ? "=> #{File.basename modified} changed, rebuilding... " :
                      'Building...'
    t = Time.now
    Polytexnic::Builders::Html.new.build
    puts "Done. (#{(Time.now - t).round(2)}s)"
  end

  def start_server(port)
    require 'polytexnic/server/app'
    rebuild
    puts "Running Polytexnic server on http://localhost:#{port}"
    $stderr = $stdout = StringIO.new
    Polytexnic::App.set :port, port
    Polytexnic::App.run!
  end

  def run(port)
    listen_for_changes
    start_server port
    Process.wait
  end
end
