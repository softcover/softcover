require 'spec_helper'

describe Polytexnic::Builders::Epub do
  before(:all) do
    generate_book
    @builder = Polytexnic::Builders::Epub.new
    silence { @builder.build! }
    chdir_to_book
  end
  after(:all) { remove_book }
  subject(:builder) { @builder }

  it "should be valid" do
    expect(`poly epub:validate`).to match(/No errors or warnings/)
  end

  describe "mimetype file" do
    it "should exist in the right directory" do
      expect('epub/mimetype').to exist
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

        it "should have the right TOC chpater refs" do
          toc_refs = doc.css('itemref').map { |node| node['idref'] }
          expect(toc_refs).to eql(%w[a_chapter another_chapter])
        end

        it "should have the right title" do
          expect(doc.to_xml).to match(/>#{builder.manifest.title}</)
        end

        it "should have the right author" do
          author = Regexp.escape(builder.manifest.author)
          expect(doc.to_xml).to match(/>#{author}</)
        end

        it "should have the right copyright line" do
          copyright = Regexp.escape("Copyright (c) 2013")
          author = Regexp.escape(builder.manifest.author)
          expect(doc.to_xml).to match(/>#{copyright} #{author}</)
        end

        it "should have a unique UUID" do
          uuid = Regexp.escape(builder.manifest.uuid)
          expect(doc.to_xml).to match(/>#{uuid}</)
        end
      end
    end

    describe "spine toc" do
      subject(:toc) { 'epub/OEBPS/toc.ncx' }
      let(:doc) { Nokogiri::XML(File.read(toc)) }

      it { should exist }

      it "should contain the right filenames in the right order" do
        filenames = ['a_chapter_fragment.html', 'another_chapter_fragment.html']
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

      it "should create the HTML files" do
        builder.manifest.chapters.each_with_index do |chapter, i|
          content = File.read("html/#{chapter.slug}_fragment.html")
          # Make sure at least one template file has math.
          expect(builder.math?(content)).to be_true if i == 0
          expect("epub/OEBPS/#{chapter.slug}_fragment.html").to exist
        end
      end

      it "should create math PNGs" do
        expect("epub/OEBPS/images/texmath").to exist
        expect(Dir["epub/OEBPS/images/texmath/*.png"]).not_to be_empty
      end
    end

    it "should create the style files" do
      expect('epub/OEBPS/styles/page-template.xpgt').to exist
      expect('epub/OEBPS/styles/pygments.css').to exist
      expect('epub/OEBPS/styles/polytexnic.css').to exist
    end
  end

  it "should generate the EPUB" do
    expect('ebooks/book.epub').to exist
    expect('epub/book.epub').not_to exist
    expect('epub/book.zip').not_to exist
  end
end

describe Polytexnic::Builders::Epub do
  context "for a Markdown book" do
    before(:all) do
      generate_book(source: :markdown)
      @builder = Polytexnic::Builders::Epub.new
      silence { @builder.build! }
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { @builder }

    it "should not raise an error" do
      expect { subject }.not_to raise_error
    end
  end
end
