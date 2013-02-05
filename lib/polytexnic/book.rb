class Polytexnic::Book
  include Polytexnic::Utils

  attr_accessor :errors, :files, :uploader, :signatures, :manifest,
    :processed_screencasts

  def initialize
    @manifest = Polytexnic::BookManifest.new
    @client = Polytexnic::Client.new_with_book self

    @processed_screencasts = []
  end

  class BookFile
    attr_accessor :path, :checksum
    def initialize(path)
      @path = path
      @checksum = Digest::MD5.hexdigest File.read path
      (@@lookup ||= {})[path] = self
    end

    def to_json(opts={})
      { path: @path, checksum: @checksum }.to_json
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

  def total_upload_size
    @upload_params.inject(0) do |sum, p|
      sum += File.size?(p['path']) || 0
    end
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

  def process_screencasts(dir)
    Dir["#{dir}/**/*.mov"].each do |path|
      next if @processed_screencasts.include?(path)

      # check if file has been written to in the last 5 seconds
      ctime = File::ctime path
      if ctime.to_i < Time.now.to_i - 5

        # start upload process here
        upload_screencast! path

        @processed_screencasts.push path
      end
    end
  end

  def upload_screencast!(path)
    checksum = Digest::MD5.hexdigest(File.read path)

    res = @client.get_screencast_upload_params path: path, checksum: checksum

    if res['upload_params']
      screencast_uploader = Polytexnic::Uploader.new res
      screencast_uploader.upload!
    end

    # ? notify upload complete?
  end

  private
    def method_missing(name, *args, &block)
      @manifest.send(name) || super
    end
end
