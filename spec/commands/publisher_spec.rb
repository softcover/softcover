require 'spec_helper'

describe Polytexnic::Commands::Publisher do
  let(:book) { Polytexnic::Book.new }

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
        Polytexnic::Commands::Publisher.publish!
      end
    end
  end
end
