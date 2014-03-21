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
    end
  end
end

