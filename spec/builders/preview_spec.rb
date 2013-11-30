require 'spec_helper'

describe Softcover::Builders::Preview do

  before(:all) do
    generate_book
    @builder = Softcover::Builders::Preview.new
    @builder.build!
    chdir_to_book
  end
  after(:all) { remove_book }

  describe "#build!" do

    it "should build a PDF" do
      expect('ebooks/book-preview.pdf').to exist
    end

    context "EPUB & MOBI books" do
      it "should build an EPUB" do
        expect('ebooks/book-preview.epub').to exist
      end

      it "should build an EPUB" do
        expect('ebooks/book-preview.mobi').to exist
      end

      it "should include the right chapters" do
        @builder.manifest.preview_chapters.each do |ch|
          expect(File.join('epub', 'OEBPS', ch.fragment_name)).to exist
        end
        nonpreview_chapters = @builder.manifest.chapters -
                              @builder.manifest.preview_chapters
        nonpreview_chapters.each do |ch|
          expect(File.join('epub', 'OEBPS', ch.fragment_name)).not_to exist
        end
      end
    end
  end
end

