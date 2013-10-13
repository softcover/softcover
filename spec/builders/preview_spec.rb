require 'spec_helper'

describe Polytexnic::Builders::Preview do

  context "for a PolyTeX book" do
    before(:all) do
      generate_book
      @builder = Polytexnic::Builders::Preview.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }

    describe "#build!" do

      it "should build a PDF" do
        expect('ebooks/book-preview.pdf').to exist
      end
    end
  end

  context "for a Markdown book" do
    before(:all) do
      generate_book(markdown: true)
      @builder = Polytexnic::Builders::Preview.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }

    describe "#build!" do

      it "should build a PDF" do
        expect('ebooks/book-preview.pdf').to exist
      end
    end
  end
end

