class Softcover::Book
  include Softcover::Utils
  include Softcover::Output

  DEFAULT_MEDIA_DIR = "media"

  attr_accessor :errors, :uploader, :signatures, :manifest,
                :processed_media, :media_dir

  class UploadError < StandardError; end

  def initialize(options={})
    require "softcover/client"
    @manifest = Softcover::BookManifest.new(options)
    @marketing = Softcover::MarketingManifest.new

    @client = Softcover::Client.new_with_book self

    @media_dir = DEFAULT_MEDIA_DIR

    @processed_media = []
  end

  class BookFile < Struct.new(:path)
    LAST_WRITE_HORIZON = 0

    attr_accessor :checksum
    def initialize(*args)
      super
      @checksum = Digest::MD5.file(path).hexdigest
      (@@lookup ||= {})[path] = self
    end

    def ready?
      return true if Softcover::test?
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
    Softcover::BookConfig['id']
  end

  def id=(n)
    Softcover::BookConfig['id'] = n
  end

  # get array of paths and checksums
  def files
    paths = %W{html/#{slug}.html html/*_fragment.html images/**/* config/*
               html/stylesheets/custom.css}
    Dir[*paths].map do |path|
      BookFile.new(path) unless File.directory?(path)
    end.compact
  end

  def filenames
    files.map &:path
  end

  def chapter_attributes
    chapters.map(&:to_hash)
  end

  def url
    # TODO: append api_token to auto-login?
    "#{@client.host}/books/#{id}/redirect"
  end

  # Opens the book in the browser (OS X & Linux).
  def open_in_browser
    `#{open} #{url}`
  end

  # Returns the system-dependent `open` command.
  def open
    if os_x?
      'open'
    elsif linux?
      'xdg-open'
    else
      raise "Platform #{RUBY_PLATFORM} not supported"
    end
  end

  def create_or_update(options={})
    raise "HTML not built!" if Dir['html/*'].empty?

    params = {
      id: id,
      files: files,
      title: title,
      slug: slug,
      subtitle: subtitle,
      description: description,
      chapters: chapter_attributes,
      prices: prices,
      faq: faq,
      testimonials: testimonials,
      marketing_content: marketing_content,
      contact_email: contact_email,
      hide_softcover_footer: hide_softcover_footer,
      author_name: author,
      authors: authors,
      ga_account: ga_account,
      repo_url: repo_url,
      remove_unused_media_bundles: options[:remove_unused_media_bundles],
      custom_math: custom_math
    }

    res = @client.create_or_update_book params

    if res['errors']
      @errors = res['errors']
      return false
    end

    # is this needed?
    @attrs = res['book']

    self.id = @attrs['id']

    # Not needed for now:
    # Softcover::BookConfig['last_uploaded_at'] = Time.now

    # res contains the S3 upload signatures needed
    @uploader = Softcover::Uploader.new res

    true

  rescue Exception => e
    @errors = [e.message]
    raise e
    false
  end

  def upload!(options={})
    @uploader.after_each do |params|
      notify_file_upload params['path']
    end

    @uploader.upload!(options)
    notify_upload_complete
  end

  def notify_upload_complete
    res = @client.notify_upload_complete

    if res['errors'].nil?
      return url
    else
      raise UploadError, "Couldn't verify upload: #{res['errors']}"
    end
  end

  def notify_file_upload(path)
    book_file = BookFile.find path

    # this could spin off new thread:
    @client.notify_file_upload path: book_file.path,
      checksum: book_file.checksum
  end

  def destroy
    res = @client.destroy
    if res['errors']
      @errors = res['errors']
      return false
    end
    true
  end

  # ============================================================================
  # Media handling
  # ============================================================================

  # 1. iterate over /media/*
  # => use directory name as path parameter
  # => get checksums for all included files
  # => send each to /media API endpoint and then upload

  def process_media(options={})
    Dir["media/*"].each do |media_dir|
      next unless File.directory?(media_dir) && !(media_dir =~ /^\./)
      process_media_directory media_dir, options
    end
  end

  def process_media_directory(dir, options={})
    return false if @processed_media.include?(dir)

    puts "Processing #{dir} directory..."

    files_to_upload = get_book_files(dir).select do |file|
      file.ready?
    end

    upload_media! dir, files_to_upload, options

    @processed_media.push dir
  end

  def get_book_files(dir)
    Dir["#{dir}/**/*"].map do |path|
      BookFile.new(path) unless File.directory?(path)
    end.compact
  end

  def upload_media!(path, files, options={})
    return if files.empty?

    manifest_path = File.join(path, "manifest.yml")
    manifest = File.exists?(manifest_path) ? File.read(manifest_path) : nil

    res = @client.get_media_upload_params path, files, manifest, options

    if res['upload_params']
      media_uploader = Softcover::Uploader.new res
      media_uploader.after_each do |params|
        notify_file_upload params['path']
      end
      media_uploader.upload!
      notify_upload_complete
    else
      raise 'server error'
    end
  end

  def custom_math
    Softcover::Mathjax.custom_macros
  end

  private
    def method_missing(name, *args, &block)
      @manifest.send(name) || @marketing.send(name) || nil
    end
end
