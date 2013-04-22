require 'spec_helper'

describe Polytexnic::Builders::Epub do
  context "in valid TeX directory" do
    before do
      chdir_to_book
      clean!
    end

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Epub.new }
      before { builder.build! }

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

      describe "contents" do

        it "should create the right HTML file" do
          expect("epub/OEBPS/#{builder.manifest.filename}.html").to exist
        end

        describe "opf file" do
          let(:content_opf) { 'epub/OEBPS/content.opf' }
          let(:doc) { Nokogiri.XML(File.read(content_opf)) }

          subject { content_opf }

          it { should exist }

          it "should have the chapter right items" do
            expect(doc.css('item#chapter-1')).not_to be_empty
            expect(doc.css('item#chapter-2')).not_to be_empty
          end

          it "should have the right TOC chpater refs" do
            toc_refs = doc.css('itemref').map { |node| node['idref'] }
            expect(toc_refs).to eql(%w[chapter-1 chapter-2])
          end
        end

        it "should have the right contents" do
          File.open('epub/OEBPS/book.html') do |f|
            expect(f.read).to match('<span>Chapter 1</span>')
          end
        end
      end

      describe "spine toc" do
        let(:toc) { 'epub/OEBPS/toc.ncx' }
        subject { toc }

        it { should exist }

        it "should contain the right filenames in the right order" do
          filenames = ['chapter-1.html', 'chapter-2.html']
          doc = Nokogiri::XML(File.read(toc))
          source_files = doc.css('content').map { |node| node['src'] }
          expect(source_files).to eql(filenames)
        end
      end

      it "should create the HTML files" do
        builder.manifest.chapters.each do |chapter|
          expect("epub/OEBPS/#{chapter.slug}.html").to exist
        end
      end
  
      it "should create the stylesheet file(s)" do
        expect('epub/OEBPS/styles/pygments.css').to exist
      end

      it "should generate the EPUB" do
        expect('epub/book.epub').to exist
        expect('epub/book.zip').not_to exist
      end

    end
  end
end

# Cleans the fixtures directory as a prep for testing.
def clean!
  FileUtils.rm_r('epub/book.epub', force: true)
  FileUtils.rm_r('epub/mimetype', force: true)
  FileUtils.rm_rf('epub/META-INF/')
  FileUtils.rm_rf('epub/OEBPS/')
end