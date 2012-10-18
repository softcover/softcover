class Polytexnic::Book
  include Polytexnic::Utils

  attr_accessor :errors, :files, 
    :total_size, :signatures, :manifest, :upload_params

  def initialize

    @manifest = Polytexnic::BookManifest.new

    @client = Polytexnic::Client.new
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
    @files ||= Dir['**/*'].map do |path| 

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

    @upload_params = res['upload_params']

    @bucket = res['bucket']
    @access_key = res['access_key']

    true

  rescue Exception => e
    puts e # should be able to switch debug mode as needed
    @errors = ["An unknown error occured."]
    false
  end

  def total_upload_size
    @upload_params.inject(0) do |sum, p|
      sum += File.size?(p['path']) || 0
    end
  end

  def upload!

    unless @upload_params.empty?
      bar = ProgressBar.create title: "Starting Upload...", 
        format: "%t |%B| %P%% %e", total: total_upload_size, smoothing: 0.75

      upload_host = "http://#{@bucket}.s3.amazonaws.com"

      @upload_params.each do |params|
        path = params['path']

        size = File.size? path

        c = Curl::Easy.new "http://#{@bucket}.s3.amazonaws.com"

        c.multipart_form_post = true

        last_chunk = 0
        c.on_progress do |_, _, ul_total, ul_now|
          uploaded = ul_now > size ? size : ul_now

          bar.title = "#{path} (#{as_size uploaded} / #{as_size size})"
          bar.progress += ul_now - last_chunk rescue nil
          last_chunk = ul_now
          true
        end

        c.http_post(
          Curl::PostField.content('key', params['key']),
          Curl::PostField.content('acl', params['acl']),
          Curl::PostField.content('Signature', params['signature']),
          Curl::PostField.content('Policy', params['policy']),
          Curl::PostField.content('Content-Type', params['content_type']),
          Curl::PostField.content('AWSAccessKeyId', @access_key),
          Curl::PostField.file('file', path)
        )

        if c.body_str =~ /Error/
          puts c.body_str
          break
        end

        book_file = BookFile.find path

        # this could spin off new thread:
        @client.notify_file_upload id, 
          path: book_file.path, 
          checksum: book_file.checksum
      end

      bar.finish
    else
      puts "Nothing to upload."
    end

    res = notify_upload_complete

    if res['errors'].nil?
      puts "Published! #{url}"
    else
      puts "Couldn't verify upload: #{res['errors']}"
    end
  end

  def notify_upload_complete
    @client.notify_upload_complete id
  end

  private
    def method_missing(name, *args, &block)
      @manifest.send(name) || super
    end
end
