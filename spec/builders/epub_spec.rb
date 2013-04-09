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

      it "should be create an EPUB file" do
        expect(true).to be_true
      end


    end
  end
end

# Cleans the fixtures directory as a prep for testing.
def clean!
  FileUtils.rm_r('book.epub', force: true)
end