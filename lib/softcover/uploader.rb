module Softcover
  class Uploader
    include Softcover::Utils

    # Takes response from S3 upload signature generation API endpoint.
    def initialize(res)
      @params = res['upload_params']
      @bucket = res['bucket']
      @access_key = res['access_key']
    end

    def after_each(&blk)
      @after_each_blk = blk
    end

    def upload!(options={})
      unless @params.empty?
        bar = ProgressBar.create title:     "Starting Upload...",
                                 format:    "%t |%B| %P%% %e",
                                 total:     total_size,
                                 smoothing: 0.75,
                                 output:    Softcover::Output.stream

        upload_host = "http://#{@bucket}.s3.amazonaws.com"

        @params.each do |params|
          path = params['path']

          size = File.size? path

          c = Curl::Easy.new "http://#{@bucket}.s3.amazonaws.com"

          c.multipart_form_post = true

          last_chunk = 0
          c.on_progress do |_, _, ul_total, ul_now|
            uploaded = ul_now > size ? size : ul_now
            x = as_size(uploaded)
            y = as_size(size)
            x = y if x > y
            begin
              bar.send(:title=, "#{path} (#{x} / #{y})")
              bar.progress += ul_now - last_chunk
              bar.refresh
            rescue
              nil
            end
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

          if @after_each_blk
            @after_each_blk.call params
          end
        end

        bar.finish
      else
        puts "Nothing to upload." unless options[:silent]
      end
      @params.size > 0
    end

    def total_size
      @params.inject(0) do |sum, p|
        sum += File.size?(p['path']) || 0
      end
    end

    def file_count
      @params.size
    end

  end
end