module Softcover::Commands::Publisher
  include Softcover::Utils
  include Softcover::Output

  extend self

  def publish!(options={})
    return false unless current_book

    if current_book.create_or_update
      require 'ruby-progressbar'
      require 'curb'
      unless options[:quiet] || options[:silent]
        puts "Uploading #{current_book.uploader.file_count} files " \
             "(#{as_size current_book.uploader.total_size}):"
      end
      url = current_book.upload!(options)
      unless options[:quiet] || options[:silent]
        puts "Published! #{url}"
      end
    else
      puts "Errors: #{current_book.errors}"
      return false
    end

    true
  rescue Softcover::BookManifest::NotFound => e
    puts e.message
    false
  rescue Softcover::Book::UploadError => e
    puts e.message
    false
  end

  def publish_media!(options={})
    return false unless current_book

    require 'ruby-progressbar'
    require 'curb'

    current_book.media_dir = options[:dir] || Softcover::Book::DEFAULT_MEDIA_DIR

    @watch = options[:watch]

    if options[:daemon]
      pid = fork do
        run_publish_media
      end

      puts "Daemonized, pid: #{pid}"
    else
      run_publish_media
    end

    current_book
  end

  def run_publish_media
    if @watch
      puts "Watching..."

      Signal.trap("TERM") do
        puts "SIGTERM received."
        exit_with_message
      end

      begin
        loop do
          process_media
          sleep 1
        end
      rescue Interrupt
        puts " Interrupt Received."
        exit_with_message
      end
    else
      process_media
      exit_with_message
    end
  end

  def process_media
    current_book.process_media
  end

  def exit_with_message
    number = current_book.processed_media.size
    dir = number == 1 ? "directory" : "directories"
    puts "Processed #{number} #{dir}"
  end

  def unpublish!(slug=nil)
    require "rest_client"
    require "softcover/client"

    if slug.present?
      begin
        res = Softcover::Client.new.destroy_book_by_slug(slug)
        if res["errors"]
          puts "Errors: #{res.errors}"
          return false
        else
          puts "Done!"
          return true
        end
      rescue RestClient::ResourceNotFound
        puts "Book with slug='#{slug}' not found under this account."
        return false
      end
    end

    return false unless current_book
    if current_book.destroy
      Softcover::BookConfig.remove
      puts "Done!"
      return true
    else
      puts "Errors: #{current_book.errors}"
      return false
    end
  rescue RestClient::ResourceNotFound
    puts "Book with ID=#{current_book.id} not found under this account."
    false
  rescue Softcover::BookManifest::NotFound => e
    puts e.message
    false
  end
end
