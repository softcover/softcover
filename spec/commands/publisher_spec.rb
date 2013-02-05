require 'spec_helper'

describe Polytexnic::Commands::Publisher do
  let(:book) { Polytexnic::Book.new }

  describe "#publish" do
    context "publishing from non book directory" do
      before do
        chdir_to_non_book
      end

      it "rejects the publish" do
        silence do
          Polytexnic::Commands::Publisher.publish!.should be_false
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
          Polytexnic::Commands::Publisher.publish!.should be_true
        end
      end
    end
  end

  describe "#publish_screencasts" do
    before do
      chdir_to_book
      book.id = 1
      stub_create_book book
    end

    it "daemonizes" do
      SimpleCov.at_exit {} # since we're forking

      silence do
        Polytexnic::Commands::Publisher.publish_screencasts! "./screencasts"
          #, daemon: true
      end

      # http://stackoverflow.com/questions/6158889/how-do-you-test-code-that-forks-using-rspec

      # subject.should_receive(:fork) do |&block|
      #   block.call
      # end
    end

  end
end
