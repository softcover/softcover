module Polytexnic::Commands::Publisher
  include Polytexnic::Utils

  extend self

  def publish!
    return false unless current_book

    if current_book.create_or_update
      require 'ruby-progressbar'
      require 'curb'
      puts "Uploading #{current_book.uploader.file_count} files " \
        "(#{as_size current_book.uploader.total_size}):"
      current_book.upload!
    else
      puts "Errors: #{current_book.errors}"
      return false
    end

    true
  end

  # TODO: refactor this flow out of file?
  def publish_screencasts!(options={})
    return false unless current_book

    current_book.screencasts_dir = options[:dir] ||
      Polytexnic::Book::DEFAULT_SCREENCASTS_DIR

    @watch = options[:watch]

    if options[:daemon]
      pid = fork do
        run_publish_screencasts
      end

      puts "Daemonized, pid: #{pid}"
    else
      run_publish_screencasts
    end

    current_book
  end

  def run_publish_screencasts
    if @watch
      puts "Watching..."

      Signal.trap("TERM") do
        puts "SIGTERM received."
        exit_with_message
      end

      begin
        loop do
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
    current_book.process_screencasts
  end

  def exit_with_message
    puts "Processed #{current_book.processed_screencasts.size} screencasts."
  end
end
