require 'spec_helper'

describe Polytexnic::Commands::Generator do
  let(:name) { "foo_bar" }

  context "generate in non-book directory" do
    before do
      chdir_to_non_book
      silence {
        Polytexnic::Commands::Generator.generate_directory name
      }
    end

    it "should copy files" do
      Polytexnic::Commands::Generator.verify!.should be_true
    end

    it "should edit book.yml" do
      yml = YAML.load_file(File.join name, 'book.yml')
      yml['title'].should eq name
    end

    context "generated contents" do

      before { Dir.chdir(name) }

      describe ".gitignore" do
        subject { File.open('.gitignore').read }

        it { should match(/\*\.aux/) }
        it { should match(/\*\.log/) }
        it { should match(/\*\.toc/) }
        it { should match(/\*\.tmp\.\*/) }
        it { should match(/\*\.pdf/) }
        it { should match(/pygments\.sty/) }
        it { should match(/html\//) }
        it { should match(/epub\//) }
        it { should match(/screencasts\//) }
        it { should match(/log\//) }
        it { should match(/\.DS_Store/) }
      end
      
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
