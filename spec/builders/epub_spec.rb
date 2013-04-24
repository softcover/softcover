require 'spec_helper'

describe Polytexnic::Builders::Epub do
  before(:all) { generate_book }
  after(:all)  { remove_book }
  subject(:builder) { Polytexnic::Builders::Epub.new }

  before { chdir_to_book }
  before { builder.build! }

  it "should be valid" do
    `poly epub:validate`.should =~ /No errors or warnings/
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
        filenames = ['a_chapter.html', 'another_chapter.html']
        source_files = doc.css('content').map { |node| node['src'] }
        expect(source_files).to eql(filenames)
      end

      it "should have the right title" do
        expect(doc.to_xml).to match(/>#{builder.manifest.title}</)
      end
    end

    it "should create the HTML files" do
      builder.manifest.chapters.each do |chapter|
        expect("epub/OEBPS/#{chapter.slug}.html").to exist
      end
    end
    
    it "should create the style files" do
      expect('epub/OEBPS/styles/page-template.xpgt').to exist
      expect('epub/OEBPS/styles/pygments.css').to exist
      expect('epub/OEBPS/styles/polytexnic.css').to exist
    end
  end

  it "should generate the EPUB" do
    expect('epub/book.epub').to exist
    expect('epub/book.zip').not_to exist
  end
end
