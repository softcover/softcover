require 'spec_helper'

describe Softcover::Commands::Publisher do
  let(:book) { Softcover::Utils.current_book }
  before(:all) { generate_book }
  after(:all)  { remove_book }

  describe "#publish" do
    context "publishing from non book directory" do
      before do
        chdir_to_non_book
      end

      it "rejects the publish" do
        expect(subject.publish!).to be_false
      end
    end

    context "publishing from book directory" do
      before do
        chdir_to_book
        stub_create_book book
      end

      it "publishes" do
        expect(subject.publish!).to be_true
      end
    end
  end

  describe "#unpublish" do
    context "unpublishing from non book directory" do
      before do
        chdir_to_non_book
      end

      it "rejects the unpublish" do
        expect(subject.unpublish!).to be_false
      end
    end

    context "unpublishing from book directory" do
      before do
        chdir_to_book
        stub_create_book book
        subject.publish!
        stub_destroy_book book
      end

      it "unpublishes" do
        expect(subject.unpublish!).to be_true
      end

      it "removes book config" do
        subject.unpublish!
        expect(Softcover::BookConfig.exists?).to be_false
      end
    end

    context "unpublishing from book directory with invalid ID" do
      before do
        chdir_to_book
        stub_create_book book
        subject.publish!
        Softcover::BookConfig['id'] = 0
        stub_destroy_book_not_found book
      end

      it "does not unpublish" do
        expect(subject.unpublish!).to be_false
      end
    end

    context "unpublishing outside book directory" do
      before do
        chdir_to_book
        stub_create_book book
        subject.publish!
        Dir.chdir(File.dirname(__FILE__))
      end

      context "with valid slug option" do
        before { stub_destroy_book_by_slug book }

        it "unpublishes" do
          expect(subject.unpublish!(book.slug)).to be_true
        end
      end

      context "with invalid slug option" do
        let(:slug) { "error" }
        before { stub_destroy_book_by_invalid_slug slug }

        it "does not unpublish" do
          expect(subject.unpublish!(slug)).to be_false
        end
      end
    end
  end

  describe "#publish_media" do
    before do
      chdir_to_book
      book.id = 1
      stub_media_upload book
    end

    # it "should start with 0 processed_media" do
    #   expect(book.processed_media.length).to eq 0
    # end

    # it "processes media" do
    #   subject.publish_media!
    #   expect(book.processed_media.length).to be > 0
    # end

    # it "daemonizes" do
    #   subject.should_receive(:fork) do |&blk|
    #     blk.call
    #   end
    #   subject.publish_media! daemon: true
    #   expect(book.processed_media.length).to be > 0
    # end

    # it "watches" do
    #   subject.should_receive(:loop) do |&blk|
    #     blk.call
    #   end
    #   subject.publish_media! watch: true
    #   expect(book.processed_media.length).to be > 0
    # end

  end
end
