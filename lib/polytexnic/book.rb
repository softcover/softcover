class Polytexnic::Book
  include Polytexnic::Utils

  DEFAULT_SCREENCASTS_DIR = "screencasts"

  attr_accessor :errors, :files, :uploader, :signatures, :manifest,
                :processed_screencasts, :screencasts_dir

  def initialize
    require "polytexnic/client"
    @manifest = Polytexnic::BookManifest.new
    @client = Polytexnic::Client.new_with_book self

    @screencasts_dir = DEFAULT_SCREENCASTS_DIR

    @processed_screencasts = []
  end

  class BookFile < Struct.new(:path)
    LAST_WRITE_HORIZON = 5

    attr_accessor :checksum
    def initialize(*args)
      super
      @checksum = Digest::MD5.hexdigest File.read path
      (@@lookup ||= {})[path] = self
    end

    def ready?
      return true if Polytexnic::test?
      File::ctime(path).to_i < Time.now.to_i - LAST_WRITE_HORIZON
    end

    def to_json(opts={})
      { path: path, checksum: @checksum }.to_json
    end

    def self.find(path)
      @@lookup[path]
    end
  end

  # TODO: extract pattern to config helper:
  #   has_config_for :id, :last_uploaded_at, path: ".polytex-book"

  def id
    Polytexnic::BookConfig['id']
  end

  def id=(n)
    Polytexnic::BookConfig['id'] = n
  end

  # get array of paths and checksums
  def files
    # question: should we use `git ls-files` instead?
    # TODO: only use pertinent files
    paths = %w{html/*_fragment.html images/**/* *.mobi *.epub *.pdf}
    Dir[*paths].reject { |path| File.directory?(path) }.map do |path|
      BookFile.new path
    end
  end

  def filenames
    files.map &:path
  end

  def chapter_attributes
    chapters.map(&:marshal_dump)
  end

  def url
    # TODO: append api_token to auto-login?
    "#{@client.host}/books/#{slug}"
  end

  def open_in_browser
    `open #{url}`
  end

  def epubcheck
    epub = File.join('ebooks', "#{manifest.filename}.epub")
    java = `which java`.strip
    if java.empty?
      system("EPUB validation requires java to be on the path")
      exit 1
    end
    epubcheck = File.join(Dir.home, 'epubcheck-3.0', 'epubcheck-3.0.jar')
    if !File.exist?(epubcheck)
      puts "Install EpubCheck version 3.0 to your home directory"
      puts 'https://code.google.com/p/epubcheck/downloads/detail?name=epubcheck-3.0.zip'
      exit 1
    end
    puts "Validating EPUB..."
    system("#{java} -jar #{epubcheck} #{epub}")
  end

  def create_or_update
    raise "HTML not built!" if Dir['html/*'].empty?

    res = @client.create_or_update_book id: id,
                                        files: files,
                                        title: title,
                                        slug: slug,
                                        subtitle: subtitle,
                                        description: description,
                                        cover: cover,
                                        chapters: chapter_attributes

    if res['errors']
      @errors = res['errors']
      return false
    end

    # is this needed?
    @attrs = res['book']

    self.id = @attrs['id']
    Polytexnic::BookConfig['last_uploaded_at'] = Time.now

    @uploader = Polytexnic::Uploader.new res

    true

  rescue Exception => e
    @errors = [e.message]
    raise e
    false
  end

  def upload!
    @uploader.after_each do |params|
      notify_file_upload params['path']
    end

    @uploader.upload!

    res = @client.notify_upload_complete

    if res['errors'].nil?
      puts "Published! http://#{url}"
    else
      puts "Couldn't verify upload: #{res['errors']}"
    end
  end

  def notify_file_upload(path)
    book_file = BookFile.find path

    # this could spin off new thread:
    @client.notify_file_upload path: book_file.path,
      checksum: book_file.checksum
  end

  # ============================================================================
  # Screencast handling
  # ============================================================================

  def process_screencasts
    files_to_upload = find_screencasts.select do |file|
      next false if @processed_screencasts.include?(file)

      file.ready?# && upload_screencast!(file)
    end

    upload_screencasts! files_to_upload

    @processed_screencasts += files_to_upload
  end

  def find_screencasts
    Dir["#{@screencasts_dir}/**/*.mov"].map{ |path| BookFile.new path }
  end

  def upload_screencasts!(files)
    return if files.empty?

    res = @client.get_screencast_upload_params files

    if res['upload_params']
      screencast_uploader = Polytexnic::Uploader.new res
      screencast_uploader.after_each do |params|
        notify_file_upload params['path']
      end
      screencast_uploader.upload!
    else
      raise 'server error'
    end
  end

  private
    def method_missing(name, *args, &block)
      @manifest.send(name) || super
    end
end
