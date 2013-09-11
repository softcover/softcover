require 'spec_helper'

describe Polytexnic::Builders::Mobi do
  context "in valid TeX directory" do
    before(:all) do
      generate_book
      @builder = Polytexnic::Builders::Mobi.new
      silence { @built = @builder.build! }
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
end

# Cleans the fixtures directory as a prep for testing.
def clean!
  FileUtils.rm_r('epub/book.epub', force: true)
  FileUtils.rm_r('epub/book.mobi', force: true)
end