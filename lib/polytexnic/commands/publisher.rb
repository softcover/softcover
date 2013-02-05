require 'ruby-progressbar'
require 'curb'

module Polytexnic::Commands::Publisher
  include Polytexnic::Utils

  extend self

  def publish!
    return false unless current_book

    if current_book.create_or_update
      puts "Uploading #{current_book.uploader.file_count} files " \
        "(#{as_size current_book.uploader.total_size}):"

      current_book.upload!
    else
      puts "Errors: #{current_book.errors}"
      return false
    end
    
    true
  end

  def publish_screencasts!(dir, options={})
    return false unless current_book

    @watch_dir = options[:watch]

    @screencasts_dir = dir

    if options[:daemon]
      pid = fork do
        STDERR.reopen("/dev/null")
        STDOUT.reopen("/dev/null")
      end

      puts "Daemonized, pid: #{pid}"
    else
      run_publish_screencasts
    end
  end

  def run_publish_screencasts
    if @watch_dir
      puts "Watching..."

      Signal.trap("TERM") do
        puts "SIGTERM received."
        exit_with_message
      end

      begin
        while true
          process_screencasts
          sleep 1
        end
      rescue Interrupt
        puts " Interrupt Received."
        exit_with_message
      end 
    else
      process_screencasts
      exit_with_message
    end
  end

  def process_screencasts
    current_book.process_screencasts @screencasts_dir
  end

  def exit_with_message
    puts "Processed #{current_book.processed_screencasts.size} screencasts."
  end
end
