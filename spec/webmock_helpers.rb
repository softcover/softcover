module WebmockHelpers
  def stub_valid_login(email, pass, api_key=TEST_API_KEY)
    stub_request(:post, "#{Polytexnic::Config::DEFAULTS[:host]}/api/v1/login").
      with(:body => {"email"=>email, "password"=>pass},
        :headers => {'Accept'=>'application/json', 
          'Accept-Encoding'=>'gzip, deflate', 
          'Content-Length'=>/.+/, 
          'Content-Type'=>'application/json', 
          'User-Agent'=>'Ruby'} ).
      to_return(:status => 200, :body => {api_key: api_key}.to_json)
  end

  def stub_invalid_login(email, pass)
    stub_request(:post, "#{Polytexnic::Config::DEFAULTS[:host]}/api/v1/login").
      with(:body => {"email"=>email, "password"=>pass}, 
        :headers => {'Accept'=>'application/json', 
          'Accept-Encoding'=>'gzip, deflate', 
          'Content-Length'=>/.+/, 
          'Content-Type'=>'application/json', 
          'User-Agent'=>'Ruby'} ).
      to_return(:status => 422, body: '')
  end

  def stub_create_book(book, test_id=1)
    test_bucket = 'test-bucket'
    test_access_key = 'asdf'

    return_body = {
      signatures: book.files.map { |f|
        {
          :policy          => "asdf",
          :signature       => "asdf",
          :acl             => "public-read",
          :content_type    => "asdf",
          :key             => File.join(book.slug, f)
        }
      },
      bucket: test_bucket,
      access_key: test_access_key,
      book: {
        id: test_id
      }
    }.to_json

    stub_request(:post, "http://polytexnic.com/api/v1/books").
      with(:body => {
          files: book.files, 
          chapter_manifest: book.chapter_manifest
        }.to_json,
           :headers => {'Accept'=>'application/json', 
            'Accept-Encoding'=>'gzip, deflate', 
            'Content-Length'=>/.+/, 
            'Content-Type'=>'application/json', 
            'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => return_body, :headers => {})

    stub_request(:head, /s3\.amazonaws\.com/).
      to_return(:status => 200, :body => "", :headers => {etag: 'asdf'}) 

    stub_request(:post, /s3\.amazonaws\.com/).
       with(:body => /.*/).
       to_return(:status => 200, :body => "", :headers => {})

    stub_request(:put, "http://polytexnic.com/api/v1/books/#{test_id}").
      with(:body => "{\"upload_complete\":true}",
        :headers => {'Accept'=>'application/json', 
          'Accept-Encoding'=>'gzip, deflate', 
          'Content-Length'=>/.*/, 
          'Content-Type'=>'application/json', 
          'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => {}.to_json, :headers => {}) 
  end

  def chdir_to_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/book"
  end

  def chdir_to_non_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/non-book"
  end
end