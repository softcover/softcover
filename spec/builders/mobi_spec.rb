require 'spec_helper'

describe Softcover::Builders::Mobi do
  describe "#build!" do
    before(:all) do
      generate_book
      @builder = Softcover::Builders::Mobi.new
      @built = @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }

    it "should generate the MOBI" do
      expect('ebooks/book.mobi').to exist
    end

    describe "MOBI command" do
      context "default" do
        let(:command) { @builder.mobi_command(@builder.mobi_filename) }
        it "should use Calibre's ebook-convert" do
          expect(command).to include 'ebook-convert'
        end
      end

      context "kindlegen" do
        let(:command) do
          @builder.mobi_command(@builder.mobi_filename, kindlegen: true)
        end
        it "should use Amazon.com's kindlegen" do
          expect(command).to include 'kindlegen'
        end
      end

      context "preview" do
        let(:filename) do
          @builder.mobi_filename(preview: true)
        end
        it "should use Calibre's ebook-convert" do
          expect(filename).to include 'book-preview'
        end
      end
    end
  end
end
