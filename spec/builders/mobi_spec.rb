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
        let(:command) do
          @builder.mobi_command(@builder.mobi_filename)
        end

        it "should use Calibre's ebook-convert" do
          expect(command).to include 'ebook-convert'
        end

        it "should build both kinds of Kindle files" do
          expect(command).to include ' --mobi-file-type both'
        end

        it "should include the cover" do
          expect(command).to include ' --cover epub/OEBPS/images/cover.jpg'
        end

        it "should configure the cover to work with Kindle desktop app" do
          expect(command).to include ' --share-not-sync'
        end
      end

      context "preview" do
        let(:filename) do
          @builder.mobi_filename(preview: true)
        end
        it "should create a preview file" do
          expect(filename).to include 'book-preview'
        end
      end
    end
  end
end
