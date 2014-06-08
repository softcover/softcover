require 'spec_helper'

describe Softcover::Builders::Epub do
  before(:all) do
    generate_book
    @file_to_be_removed = path('html/should_be_removed.html')
    File.write(@file_to_be_removed, '')
    silence { `softcover build:epub` }
    @builder = Softcover::Builders::Epub.new
    @builder.build!
  end
  after(:all) { remove_book }
  subject(:builder) { @builder }

  it "should be valid" do
    output = `softcover epub:validate`
    expect(output).to match(/No errors or warnings/)
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
        filenames = %w[frontmatter_fragment.html a_chapter_fragment.html
                       another_chapter_fragment.html
                       yet_another_chapter_fragment.html]
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
        expect(path('epub/OEBPS/cover.html')).to exist
        builder.manifest.chapters.each_with_index do |chapter, i|
          content = File.read(path("html/#{chapter.slug}_fragment.html"))
          has_math ||= builder.math?(content)
          fragment = path("epub/OEBPS/#{chapter.slug}_fragment.html")
          expect(fragment).to exist
        end
        # Make sure at least one template file has math.
        expect(has_math).to be_true
      end

      describe "cover file" do
        subject(:cover_file) { File.read(path('epub/OEBPS/cover.html')) }
        it "should have the right cover image" do
          expect(cover_file).to include 'cover.jpg'
        end
      end

      it "should create math PNGs" do
        expect(path("epub/OEBPS/images/texmath")).to exist
        expect(Dir[path("epub/OEBPS/images/texmath/*.png")]).not_to be_empty
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
    before(:all) do
      generate_book(markdown: true)
      @builder = Softcover::Builders::Epub.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { @builder }

    it "should be valid" do
      expect(`softcover epub:validate`).to match(/No errors or warnings/)
    end

    it "should not raise an error" do
      expect { subject }.not_to raise_error
    end

    it "should remove the generated LaTeX files" do
      expect(Dir.glob(path('chapters/*.tex'))).to be_empty
    end
  end
end
