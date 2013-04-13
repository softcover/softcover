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

        it "should create the right OPF file" do
          expect('epub/OEBPS/content.opf').to exist
        end

        it "should have the right contents" do
          File.open('epub/OEBPS/book.html') do |f|
            expect(f.read).to match('Chapter 1')
          end
        end
      end

      it "should generate the toc files" do
        expect('epub/OEBPS/toc.ncx').to exist
        expect('epub/OEBPS/toc.html').to exist
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
  FileUtils.rm_r('epub/OEBPS/*', force: true)
  FileUtils.rm_r('epub/mimetype', force: true)
  FileUtils.rm_rf('epub/META-INF/')
end