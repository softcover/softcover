require 'spec_helper'

describe Polytexnic::Commands::Generator do
  let(:name) { "test-book" }

  context "generate in non-book directory" do
    before do 
      chdir_to_non_book 
      silence { Polytexnic::Commands::Generator.generate_directory name }
    end

    it "should copy files" do
      Polytexnic::Commands::Generator.verify!.should be_true
    end

  end

  context "overwriting" do
    before do 
      chdir_to_non_book 
      $stdin.should_receive(:gets).and_return("a")

      silence do 
        2.times { Polytexnic::Commands::Generator.generate_directory name }
      end
    end

    it "should overwrite files" do
      Polytexnic::Commands::Generator.verify!.should be_true
    end
  end

  after do
    chdir_to_non_book
    FileUtils.rm_rf name
  end
end
