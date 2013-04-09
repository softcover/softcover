require 'spec_helper'

describe Polytexnic::Builders::Pdf do
  context "in valid TeX directory" do
    before do
      chdir_to_book
      clean!
    end

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Epub.new }
      before { builder.build! }

      it "should be create a tmp LaTeX file" do
        expect(true).to be_true
        expect(Polytexnic::Utils.tmpify('book.tex')).to exist
      end

    end
  end
end

# Cleans the fixtures directory as a prep for testing.
def clean!
  FileUtils.rm_r('book.epub', force: true)
end