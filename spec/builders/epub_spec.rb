require 'spec_helper'

describe Softcover::Builders::Epub do
  before(:all) do
    generate_book
    @file_to_be_removed = path('html/should_be_removed.xhtml')
    File.write(@file_to_be_removed, '')
    silence { `softcover build:epub` }
    @builder = Softcover::Builders::Epub.new
    @builder.build!
  end
  after(:all) { remove_book }
  subject(:builder) { @builder }

  it "should be valid" do
    output = `softcover epub:validate`
    english = "No errors or warnings"
    # I (mhartl) sometimes set my system language to Spanish.
    spanish = "No se han detectado errores o advertencias"
    expect(output).to match(/(#{english}|#{spanish})/)
  end

  describe "mimetype file" do
    it "should exist in the right directory" do
      expect(path('epub/mimetype')).to exist
    end

    it "should have the right contents" do
      File.open('epub/mimetype') do |f|
        expect(f.read).to match(/application\/epub\+zip/)
      end
    end
  end

  describe "META-INF" do
    it "should have the right container file" do
      expect('epub/META-INF/container.xml').to exist
    end

    it "should have an iBooks XML file" do
      expect('epub/META-INF/com.apple.ibooks.display-options.xml').to exist
    end

    it "should have the right contents" do
      File.open('epub/META-INF/container.xml') do |f|
        expect(f.read).to match(/rootfile full-path="OEBPS\/content.opf"/)
      end
    end
  end

  describe "OEBPS" do
    describe "contents" do
      describe "opf file" do
        let(:content_opf) { 'epub/OEBPS/content.opf' }
        let(:doc) { Nokogiri.XML(File.read(content_opf)) }

        subject { content_opf }

        it { should exist }

        it "should have the chapter right items" do
          expect(doc.css('item#a_chapter')).not_to be_empty
          expect(doc.css('item#another_chapter')).not_to be_empty
        end

        it "should have the right TOC chapter refs" do
          toc_refs = doc.css('itemref').map { |node| node['idref'] }
          expect(toc_refs).to eq %w[cover frontmatter a_chapter another_chapter
                                    yet_another_chapter]
        end

        it "should have the right title" do
          expect(doc.to_xml).to match(/>#{builder.manifest.title}</)
        end

        it "should have the right author" do
          author = Regexp.escape(builder.manifest.author)
          expect(doc.to_xml).to match(/>#{author}</)
        end

        it "should have the right copyright line" do
          copyright = Regexp.escape("Copyright (c) #{Time.new.year}")
          author = Regexp.escape(builder.manifest.author)
          expect(doc.to_xml).to match(/>#{copyright} #{author}</)
        end

        it "should have a unique UUID" do
          uuid = Regexp.escape(builder.manifest.uuid)
          expect(doc.to_xml).to match(/#{uuid}</)
        end

        it "should have the right conver meta tag" do
          meta = '<meta name="cover" content="img-cover-jpg"/>'
          expect(doc.to_xml).to include meta
        end
      end

      context "stylesheets directory" do
        it "should have a Pygments CSS file" do
          expect('epub/OEBPS/styles/pygments.css').to exist
        end

        it "should have a page template file" do
          expect('epub/OEBPS/styles/page-template.xpgt').to exist
        end

        it "should have a PolyTeXnic CSS file" do
          expect('epub/OEBPS/styles/softcover.css').to exist
        end

        it "should have an EPUB CSS file" do
          expect('epub/OEBPS/styles/epub.css').to exist
        end
      end
    end

    describe "spine toc" do
      subject(:toc) { 'epub/OEBPS/toc.ncx' }
      let(:doc) { Nokogiri::XML(File.read(toc)) }

      it { should exist }

      it "should contain the right filenames in the right order" do
        filenames = %w[frontmatter_fragment.xhtml a_chapter_fragment.xhtml
                       another_chapter_fragment.xhtml
                       yet_another_chapter_fragment.xhtml]
        source_files = doc.css('content').map { |node| node['src'] }
        expect(source_files).to eql(filenames)
      end

      it "should have the right title" do
        expect(doc.to_xml).to match(/>#{builder.manifest.title}</)
      end
    end

    context "HTML generation" do

      context "math? method" do
        it "should return true when there's math" do
          expect(builder.math?('\(')).to be_true
          expect(builder.math?('\[')).to be_true
          expect(builder.math?('\begin{equation}')).to be_true
        end

        it "should return false when there's no math" do
          expect(builder.math?('foo')).to be_false
        end
      end

      it "should remove the HTML files" do
        expect(@file_to_be_removed).not_to exist
      end

      it "should create the HTML files" do
        has_math = false
        expect(path('epub/OEBPS/cover.xhtml')).to exist
        builder.manifest.chapters.each_with_index do |chapter, i|
          content = File.read(path("html/#{chapter.slug}_fragment.html"))
          has_math ||= builder.math?(content)
          fragment = path("epub/OEBPS/#{chapter.slug}_fragment.xhtml")
          expect(fragment).to exist
        end
        # Make sure at least one template file has math.
        expect(has_math).to be_true
      end

      describe "cover file" do
        subject(:cover_file) { File.read(path('epub/OEBPS/cover.xhtml')) }
        it "should have the right cover image" do
          expect(cover_file).to include 'cover.jpg'
        end
      end

      it "should create math PNGs" do
        expect(path("epub/OEBPS/images/texmath")).to exist
        expect(Dir[path("epub/OEBPS/images/texmath/*.png")]).not_to be_empty
      end

      it "should record vertical-align of inline math SVGs" do
        content = File.read(path("./epub/OEBPS/a_chapter_fragment.xhtml"))
        html = Nokogiri::HTML(content)
        math_imgs = html.search('span.inline_math img')
        math_imgs.each do |math_img|
          expect(math_img['style']).to match /vertical-align/
        end
      end

      it "should not add vertical-align to displayed math" do
        content = File.read(path("./epub/OEBPS/a_chapter_fragment.xhtml"))
        html = Nokogiri::HTML(content)
        math_imgs = html.search('div.equation img')
        math_imgs.each do |math_img|
          expect(math_img['style']).not_to match /vertical-align/
        end
      end
    end

    it "should create the style files" do
      expect(path('epub/OEBPS/styles/page-template.xpgt')).to exist
      expect(path('epub/OEBPS/styles/pygments.css')).to exist
      expect(path('epub/OEBPS/styles/softcover.css')).to exist
    end

    it "should scrub the CSS file of the book id" do
      css = File.read(path('epub/OEBPS/styles/softcover.css'))
      expect(css).not_to match /\#book/
    end
  end

  it "should generate the EPUB" do
    expect(path('ebooks/book.epub')).to exist
    expect(path('epub/book.epub')).not_to exist
    expect(path('epub/book.zip')).not_to exist
  end
end

describe Softcover::Builders::Epub do
  context "for a Markdown book" do
    let(:unused_image) { File.basename(path('html/images/testimonial_1.png')) }
    before(:all) do
      generate_book(markdown: true)
      @builder = Softcover::Builders::Epub.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { @builder }

    it "should be valid" do
      output = `softcover epub:validate`
      english = "No errors or warnings"
      # I (mhartl) sometimes set my system language to Spanish.
      spanish = "No se han detectado errores o advertencias"
      expect(output).to match(/(#{english}|#{spanish})/)
    end

    it "should not raise an error" do
      expect { subject }.not_to raise_error
    end

    it "should remove the generated LaTeX files" do
      expect(Dir.glob(path('chapters/*.tex'))).to be_empty
    end

    it "should not include an image not used in the document" do
      expect(path("epub/OEBPS/images/#{unused_image}")).not_to exist
    end
  end
end

describe Softcover::EpubUtils do
  let(:dummy_class) { Class.new { include Softcover::EpubUtils } }
  let(:title) { 'Foo Bar & Grill' }
  let(:uuid) { '550e8400-e29b-41d4-a716-446655440000' }

  context "content.opf template" do
    let(:copyright) { '2015' }
    let(:author) { "Laurel & Hardy" }
    let(:cover_id) { '17' }
    let(:toc_chapters) { [] }
    let(:manifest_chapters) { [] }
    let(:images) { [] }

    let(:template) do
      dummy_class.new.content_opf_template(title, copyright, author, uuid,
                                           cover_id, toc_chapters,
                                           manifest_chapters, images)
    end

    it "should have the right (escaped) content" do
      expect(template).to include('Foo Bar &amp; Grill')
      expect(template).to include('Laurel &amp; Hardy')
      expect(template).to include(copyright)
      expect(template).to include(uuid)
      expect(template).to include(cover_id)
    end
  end

  context "toc.ncx template" do
    let(:chapter_nav) { [] }
    let(:template) do
      dummy_class.new.toc_ncx_template(title, uuid, chapter_nav)
    end

    it "should have the right (escaped) content" do
      expect(template).to include('Foo Bar &amp; Grill')
      expect(template).to include(uuid)
    end
  end

  context "nav.xhtml template" do
    let(:nav_list) { [] }
    let(:template) do
      dummy_class.new.nav_html_template(title, nav_list)
    end

    it "should have the right (escaped) content" do
      expect(template).to include('Foo Bar &amp; Grill')
    end
  end
end

describe "article validation" do
  before(:all) do
    generate_book(markdown: true, article: true)
    @file_to_be_removed = path('html/should_be_removed.xhtml')
    File.write(@file_to_be_removed, '')
    silence { `softcover build:epub` }
    @builder = Softcover::Builders::Epub.new
    @builder.build!
  end
  after(:all) { remove_book }
  subject(:builder) { @builder }

  it "should be valid" do
    output = `softcover epub:validate`
    english = "No errors or warnings"
    # I (mhartl) sometimes set my system language to Spanish.
    spanish = "No se han detectado errores o advertencias"
    expect(output).to match(/(#{english}|#{spanish})/)
  end

  it "should description" do
    commands = Softcover::Commands::Deployment.default_commands
    expect(commands).not_to include('preview')
  end
end