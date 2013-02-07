class Polytexnic::Book
  include Polytexnic::Utils

  DEFAULT_SCREENCASTS_DIR = "screencasts"

  attr_accessor :errors, :files, :uploader, :signatures, :manifest,
    :processed_screencasts, :screencasts_dir

  def initialize
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
    paths = %w{html/**/* images/**/* *.mobi *.epub *.pdf}
    @files ||= Dir[*paths].map do |path| 

      next nil unless !File.directory?(path) && 
        !(File.extname(path) == ".html" && !(path =~ /_fragment/)) &&
        path != "html/#{slug}.html" && 
        path != "html/#{slug}_fragment.html"

      BookFile.new path 
    end.compact
  end

  def filenames
    files.map &:path
  end

  def chapter_attributes
    chapters.map(&:marshal_dump)
  end

  # TODO: use with `polytexnic open` or `polytexnic info`
  def url
    "#{@client.host}/books/#{slug}"
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
      book_file = BookFile.find params['path']

      # this could spin off new thread:
      @client.notify_file_upload path: book_file.path, 
        checksum: book_file.checksum
    end

    @uploader.upload! 

    res = @client.notify_upload_complete

    if res['errors'].nil?
      puts "Published! #{url}"
    else
      puts "Couldn't verify upload: #{res['errors']}"
    end
  end

  # ============================================================================
  # Screencast handling
  # ============================================================================

  def process_screencasts
    find_screencasts.each do |file|
      next if @processed_screencasts.include?(file)

      if file.ready? && upload_screencast!(file)
        @processed_screencasts.push file
      end
    end
  end

  def find_screencasts
    Dir["#{@screencasts_dir}/**/*.mov"].map{|path| BookFile.new path }
  end

  def upload_screencast!(file)
    res = @client.get_screencast_upload_params file

    if res['upload_params']
      screencast_uploader = Polytexnic::Uploader.new res
      screencast_uploader.upload!
      return true
    end

    # ? notify upload complete?
  end

  private
    def method_missing(name, *args, &block)
      @manifest.send(name) || super
    end
end
