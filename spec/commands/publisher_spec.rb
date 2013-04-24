require 'spec_helper'

describe Polytexnic::Commands::Publisher do
  let(:book) { Polytexnic::Utils.current_book }
  before(:all) { generate_book }
  after(:all)  { remove_book }

  describe "#publish" do
    context "publishing from non book directory" do
      before do
        chdir_to_non_book
      end

      it "rejects the publish" do
        silence do
          expect(subject.publish!).to be_false
        end
      end
    end

    context "publishing from book directory" do
      before do
        chdir_to_book
        stub_create_book book
      end

      it "publishes" do
        silence do
          expect(subject.publish!).to be_true
        end
      end
    end
  end

  describe "#publish_screencasts" do
    before do
      chdir_to_book
      book.id = 1
      stub_screencasts_upload book
    end

    it "should start with 0 processed_screencasts" do
      expect(book.processed_screencasts.length).to eq 0
    end

    it "processes screencasts" do

      silence do
        subject.publish_screencasts!
      end

      expect(book.processed_screencasts.length).to be > 0
    end

    it "daemonizes" do
      subject.should_receive(:fork) do |&blk|
        blk.call
      end

      silence do
        subject.publish_screencasts! daemon: true
      end

      expect(book.processed_screencasts.length).to be > 0
    end

    it "watches" do
      subject.should_receive(:loop) do |&blk|
        blk.call
      end

      silence do
        subject.publish_screencasts! watch: true
      end

      expect(book.processed_screencasts.length).to be > 0
    end

  end
end
