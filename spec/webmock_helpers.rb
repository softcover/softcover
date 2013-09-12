module WebmockHelpers
  def api_base_url
    "#{Polytexnic::BaseConfig::DEFAULTS[:host]}/api/v1"
  end

  def test_bucket; 'test-bucket' end
  def test_access_key; 'asdf' end
  def test_id; 1 end

  HEADERS = { 'Accept'=>'application/json',
              'Accept-Encoding'=>'gzip, deflate',
              'Content-Length'=>/.+/,
              'Content-Type'=>'application/json',
              'User-Agent'=>'Ruby' }

  def stub_valid_login(email, pass, api_key=TEST_API_KEY)
    stub_request(:post, "#{api_base_url}/login").
      with(:body => { "email" => email, "password" => pass },
           :headers => HEADERS ).
      to_return(:status => 200, :body => {api_key: api_key}.to_json)
  end

  def stub_invalid_login(email, pass)
    stub_request(:post, "#{api_base_url}/login").
      with(:body => { "email" => email, "password" => pass },
           :headers => HEADERS ).
      to_return(:status => 422, body: '')
  end

  def stub_create_book(book)

    return_body = {
      upload_params: book.files.map { |f|
        {
          :policy          => "asdf",
          :signature       => "asdf",
          :acl             => "public-read",
          :content_type    => "asdf",
          :key             => File.join(book.slug, f.path),
          :path            => f.path
        }
      },
      bucket: test_bucket,
      access_key: test_access_key,
      book: {
        id: test_id
      }
    }.to_json

    stub_request(:post, "#{api_base_url}/books").
      with(:body => {
           id: book.id,
           files: book.files,
           title: book.title,
           slug: book.slug,
           subtitle: book.subtitle,
           description: book.description,
           cover: book.cover,
           chapters: book.chapter_attributes
        }.to_json,
           :headers => HEADERS).
      to_return(:status => 200, :body => return_body, :headers => {})

    stub_s3_post

    book.files.each { |file| stub_notify_file_upload file }

    stub_request(:put, "#{api_base_url}/books/#{test_id}").
      with(:body => "{\"upload_complete\":true}",
        :headers => HEADERS).
        to_return(:status => 200, :body => {}.to_json, :headers => {})
  end

  def stub_notify_file_upload(file)
    notify_file_url = "#{api_base_url}/books/#{test_id}/notify_file_upload"

    stub_request(:post, notify_file_url).
         with(:body =>
            { path: file.path, checksum: file.checksum }.to_json,
              :headers => HEADERS).
         to_return(:status => 200, :body => {}.to_json, :headers => {})
  end

  def stub_s3_post
    stub_request(:post, /s3\.amazonaws\.com/).
                 with(:body => /.*/).
                 to_return(:status => 200, :body => "", :headers => {})
  end

  def stub_screencasts_upload(book)
    stub_s3_post

    files = book.find_screencasts
    stub_request(:post,
                 "#{api_base_url}/books/#{book.id}/screencasts").
                  with(:body => {files: files }.to_json,
                       :headers => HEADERS).
                  to_return(:status => 200, :body => {
                            upload_params: files.map { |file|
                              {
                                :policy          => "asdf",
                                :signature       => "asdf",
                                :acl             => "public-read",
                                :content_type    => "asdf",
                                :key             => File.join(book.slug,
                                                              file.path),
                                :path            => file.path
                              }
                             },
                            bucket: test_bucket,
                            access_key: test_access_key
                           }.to_json, :headers => {})

    files.each { |file| stub_notify_file_upload file }
  end

  def prepare_book_stubs
    chdir_to_book
  end

  def chdir_to_fixtures
    Dir.chdir File.join File.dirname(__FILE__), "fixtures"
  end

  def chdir_to_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/book"
  end

  def chdir_to_md_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/md-book"
  end

  def chdir_to_non_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/non-book"
  end

  # Generates a sample book using the same method as `poly new`.
  # It also creates test books of all standard formats and a screencasts
  # directory with a stub file.
  def generate_book(options = {})
    name   = options[:name] || 'book'
    source = options[:format] || :polytex
    remove_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/"
    silence do
      Polytexnic::Commands::Generator.generate_directory(name,
                                                         source == :markdown)
    end
    chdir_to_book
    Polytexnic::FORMATS.each do |format|
      File.open("test-book.#{format}", 'w') { |f| f.write('test') }
    end
    Dir.mkdir("screencasts") unless File.directory?("screencasts")
    File.open(File.join('screencasts', 'ch1.mov'), 'w') { |f| f.write('test') }
  end

  def remove_book
    FileUtils.rm_rf(File.join File.dirname(__FILE__), "fixtures/book")
    chdir_to_fixtures
  end
end