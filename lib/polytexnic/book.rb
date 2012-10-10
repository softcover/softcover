class Polytexnic::Book
  attr_accessor :errors, :files, :total_size

  def initialize
    @files = Dir['**/*'].select do |f| 
      !File.directory?(f) && !(f =~ /_fragment/)
    end

    @total_size = @files.inject(0) { |sum, f| sum += File.size? f }

    @client = Polytexnic::Client.new
  end

  def create
    res = @client.create_book @files

    if res['book']['errors'] 
      @errors = res['book']['errors']
      return false
    end

    @attrs = res['book']

    @signatures = res['signatures']
    @bucket = res['bucket']
    @access_key = res['access_key']

    true

  rescue Exception => e
    puts e # should be able to switch debug mode as needed
    @errors = ["An unknown error occured."]
    false
  end

  def upload!
    bar = ProgressBar.create title: "Starting Upload...", 
      format: "%t |%B| %P%% %e", total: @total_size, smoothing: 0.75

    upload_host = "http://#{@bucket}.s3.amazonaws.com"

    @files.each_with_index do |path,i|

      # not so clean:
      params = @signatures[i]

      size = File.size? path

      # check etag against checksum
      head = Curl::Easy.http_head File.join(upload_host, params['key'])
      etag = head.header_str[/ETag: "(.*?)"/,1]
      digest = Digest::MD5.hexdigest(File.read(path))

      if digest == etag
        bar.title = "#{path} no change"
        bar.progress += size
        next
      end

      c = Curl::Easy.new "http://#{@bucket}.s3.amazonaws.com"

      c.multipart_form_post = true

      last_chunk = 0
      c.on_progress do |_, _, ul_total, ul_now|
        bar.title = "#{path} (#{as_size ul_now} / #{as_size size})"
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
    end

    if notify_upload_complete
      puts "Published! #{@client.host}/books/#{@attrs['slug']}"
    else
      puts "Couldn't verify upload, please try again."
    end
  end

  def notify_upload_complete
    res = @client.notify_upload_complete @attrs['id']
    JSON(res)
  end

end


