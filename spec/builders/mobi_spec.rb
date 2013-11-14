require 'spec_helper'

describe Softcover::Builders::Mobi do
  context "for a PolyTeX book" do
    before(:all) do
      generate_book
      @builder = Softcover::Builders::Mobi.new
      @built = @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }

    describe "#build!" do
      it "should generate the EPUB" do
        expect('ebooks/book.epub').to exist
      end

      # Because of the way kindlegen uses tempfiles, testing for the
      # actual generation of the MOBI causes an error, so we just
      # check the command.
      describe "MOBI generation" do
        subject(:built) { @built }
        it { should match /kindlegen/ }
        it { should match /ebooks\/book\.epub/ }
      end
    end
  end

  context "for a Markdown book" do
    before(:all) do
      generate_book(markdown: true)
      @builder = Softcover::Builders::Mobi.new
      @built = @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }

    describe "#build!" do
      describe "MOBI generation" do
        subject(:built) { @built }
        it { should match /kindlegen/ }
        it { should match /ebooks\/book\.epub/ }
        it { should_not match /Book.txt.epub/ }
      end
    end
  end
end
