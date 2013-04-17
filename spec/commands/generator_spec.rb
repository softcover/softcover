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

      it "should build all formats without error" do
        expect { `poly build` }.not_to raise_error
      end

      it "should have a base LaTeX file" do
        expect('foo_bar.tex').to exist
      end

      it "should have chapter files" do
        expect('chapters/a_chapter.tex').to exist
        expect('chapters/another_chapter.tex').to exist
      end

      describe ".gitignore" do
        subject { File.read('.gitignore') }

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

      describe "styles" do

        it "should have a PolyTeXnic style file" do
          expect('polytexnic.sty').to exist
        end
        
        it "should include the polytexnic style file by default" do
          book_base = File.read('foo_bar.tex')
          expect(book_base).to match(/^\\usepackage{polytexnic}/)
        end
      end
      
      describe "base LaTeX file" do
        subject { File.read('foo_bar.tex') }

        it { should match(/\\include{chapters\/a_chapter}/) }
        it { should match(/\\include{chapters\/another_chapter}/) }
        it { should match(/\\title{.*?}/) }
        it { should match(/\\author{.*?}/) }
      end

      shared_examples "a chapter" do
        it { should include('\chapter') }
        it { should include('\label') }
      end

      describe "first chapter file" do
        subject { File.read('chapters/a_chapter.tex') }
        it_should_behave_like "a chapter"
      end

      describe "second chapter file" do
        subject { File.read('chapters/another_chapter.tex') }
        it_should_behave_like "a chapter"
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
