require 'spec_helper'

describe Polytexnic::Builders::Mobi do
  context "in valid TeX directory" do
    before(:all) do
      if `which kindlegen` == ''
        url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
        msg = "No kindlegen found, install here: #{url}"
        raise msg
      end
    end

    before(:all) { generate_book }
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Mobi.new }
      before { @built = builder.build! }

      it "should generate the EPUB" do
        expect('epub/book.epub').to exist
      end

      # Because of the way kindlegen uses tempfiles, testing for the
      # actual generation of the MOBI causes an error, so we just
      # check the command.
      it "should generate the MOBI" do
        expect(@built).to match(/kindlegen/)
        expect(@built).to match(/epub\/book.epub/)
      end

    end
  end
end

# Cleans the fixtures directory as a prep for testing.
def clean!
  FileUtils.rm_r('epub/book.epub', force: true)
  FileUtils.rm_r('epub/book.mobi', force: true)
end