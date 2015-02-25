module WebmockHelpers
  def api_base_url
    "#{Softcover::BaseConfig::DEFAULTS[:host]}/api/v1"
  end

  def test_bucket; 'test-bucket' end
  def test_access_key; 'asdf' end
  def test_id; 1 end

  def headers(with_content_length=true)
    hash = { 'Accept'=>'application/json',
      'Accept-Encoding'=>'gzip, deflate',
      'Content-Type'=>'application/json',
      'User-Agent'=>'Ruby'
    }
    hash['Content-Length'] = /.+/ if with_content_length
    hash
  end

  def stub_valid_login(email, pass, api_key=TEST_API_KEY)
    stub_request(:post, "#{api_base_url}/login").
      with(:body => { "email" => email, "password" => pass },
           :headers => headers ).
      to_return(:status => 200, :body => {api_key: api_key}.to_json)
  end

  def stub_invalid_login(email, pass)
    stub_request(:post, "#{api_base_url}/login").
      with(:body => { "email" => email, "password" => pass },
           :headers => headers ).
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
           chapters: book.chapter_attributes,
           prices: book.prices,
           faq: book.faq,
           testimonials: book.testimonials,
           marketing_content: '',
           contact_email: book.contact_email,
           hide_softcover_footer: book.hide_custom_domain_footer,
           author_name: book.author,
           authors: book.authors,
           ga_account: book.ga_account,
           repo_url: book.repo_url,
           remove_unused_media_bundles: true,
           custom_math: book.custom_math
        }.to_json,
           :headers => headers).
      to_return(:status => 200, :body => return_body, :headers => {})

    stub_s3_post

    book.files.each { |file| stub_notify_file_upload file }

    stub_request(:put, "#{api_base_url}/books/#{test_id}").
      with(:body => "{\"upload_complete\":true}",
        :headers => headers).
        to_return(:status => 200, :body => {}.to_json, :headers => {})
  end

  def stub_destroy_book(book)
    stub_request(:delete, "#{api_base_url}/books/#{book.id}?api_key=").
      with(:headers => headers(false)).
      to_return(:status => 200, :body => "", :headers => {})
  end

  def stub_destroy_book_by_slug(book)
    stub_request(:delete, "#{api_base_url}/books/#{book.slug}?api_key=").
      with(:headers => headers(false)).
      to_return(:status => 200, :body => "", :headers => {})
  end

  def stub_destroy_book_by_invalid_slug(slug)
    stub_request(:delete, "#{api_base_url}/books/#{slug}?api_key=").
      with(:headers => headers(false)).
      to_return(:status => 404, :body => "", :headers => {})
  end

  def stub_destroy_book_not_found(book)
    stub_request(:delete, "#{api_base_url}/books/#{book.id}?api_key=").
      with(:headers => headers(false)).
      to_return(:status => 404, :body => "", :headers => {})
  end

  def stub_notify_file_upload(file)
    notify_file_url = "#{api_base_url}/books/#{test_id}/notify_file_upload"

    stub_request(:post, notify_file_url).
         with(:body =>
            { path: file.path, checksum: file.checksum }.to_json,
              :headers => headers).
         to_return(:status => 200, :body => {}.to_json, :headers => {})
  end

  def stub_s3_post
    stub_request(:post, /s3\.amazonaws\.com/).
                 with(:body => /.*/).
                 to_return(:status => 200, :body => "", :headers => {})
  end

  def stub_media_upload(book, dir='ebooks', options={})
    stub_s3_post
    stub_create_book(book)

    files = book.get_book_files(dir)
    stub_request(:post,
                 /\/books\/#{book.id || '.+'}\/media/).
                  with(:body => {
                                  path: dir,
                                  files: files,
                                  manifest: nil,
                                  remove_unused_media_files:
                                    options[:remove_unused_media_files]
                                }.to_json,
                       :headers => headers).
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
    dir = File.join File.dirname(__FILE__), "fixtures", "book"
    File.mkdir(dir) unless File.directory?(dir)
    Dir.chdir dir
  end

  def chdir_to_non_book
    dir = File.join File.dirname(__FILE__), "fixtures", "non-book"
    File.mkdir(dir) unless File.directory?(dir)
    Dir.chdir dir
  end

  # Generates a sample book using the same method as `softcover new`.
  # It also creates test books of all standard formats and a screencasts
  # directory with a stub file.
  def generate_book(options = {})
    name   = options[:name]   || 'book'
    source = options[:source] || :polytex
    remove_book
    Dir.chdir File.join File.dirname(__FILE__), "fixtures/"
    flags = []
    flags << '-p' unless options[:markdown]
    silence { system "softcover new #{name} #{flags.join(' ')}" }
    chdir_to_book
    File.mkdir 'html' unless File.exist?('html')
    File.write(File.join('html', 'chapter-1.html'),          'test')
    File.write(File.join('html', 'chapter-1_fragment.html'), 'test')
    File.write(File.join('html', 'test_fragment.html'),      'test')
    File.write(File.join('html', "#{name}.html"),            'test')
    mkdir path('html/images')
    mkdir 'ebooks'
    Softcover::FORMATS.each do |format|
      dir = format == 'html' ? 'html' : 'ebooks'
      File.write(File.join(dir, "test-book.#{format}"), 'test')
    end
    Dir.mkdir("screencasts") unless File.directory?("screencasts")
    File.open(File.join('screencasts', 'ch1.mov'), 'w') { |f| f.write('test') }
  end

  def remove_book
    FileUtils.rm_rf(File.join File.dirname(__FILE__), "fixtures/book")
    chdir_to_fixtures
  end
end
