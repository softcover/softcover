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
      expect(Polytexnic::Commands::Generator.verify!).to be_true
    end

    describe "book.yml" do
      subject(:yml) { YAML.load_file(File.join name, 'book.yml') }

      it "should have the right title" do
        expect(yml['title']).to eq name
      end

      it "should have the right copyright year" do
        expect(yml['copyright']).to eq Time.new.year
      end

      it "should have a UUID" do
        expect(yml['uuid']).not_to be_blank
      end
    end

    context "generated contents from template" do

      before { Dir.chdir(name) }

      it "should build all formats without error" do
        expect { `poly build` }.not_to raise_error
      end

      describe "base LaTeX file" do
        subject(:base) { 'foo_bar.tex' }
        it { should exist }
        it "should use the 14-point extbook doctype" do
          expect(File.read(base)).to match(/\[14pt\]\{extbook\}/)
        end
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

      describe "CSS" do

        let(:css_file) { 'html/stylesheets/polytexnic.css' }

        it "should have a polytexnic CSS file" do
          expect(css_file).to exist
        end
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
      expect(Polytexnic::Commands::Generator.verify!).to be_true
    end
  end

  after do
    chdir_to_non_book
    FileUtils.rm_rf name
  end
end
