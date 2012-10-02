require 'ruby-progressbar'
require 'curb'

module Polytexnic::Commands::Publisher
  extend self

  def publish!
    # verify directory has .polytexnic-book

    Dir['*'].each do |path|
      next if File.directory?(path)

      size = File.size? path
      puts "posting #{path} (#{size})"

      bar = ProgressBar.create title: path, format: "%t: |%B| %p%%"

      c = Curl::Easy.new "http://localhost:3000/upload_test"
      c.multipart_form_post = true
      c.on_progress do |chunk_size|
        bar.progress += size / chunk_size unless chunk_size == 0.0
        true
      end

      c.http_post(Curl::PostField.file('thing[file]', path))
    end
  end
end
