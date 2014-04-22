require 'spec_helper'

describe Softcover::Commands::Generator do

  context "generate PolyTeX in non-book directory" do

    before(:all) do
      chdir_to_non_book
      @name = 'foo_bar'
      Softcover::Commands::Generator.generate_file_tree @name, polytex: true
    end

    let(:name) { @name }

    before do
      chdir_to_non_book
    end

    after(:all) do
      chdir_to_non_book
      FileUtils.rm_rf name
    end

    it "should copy files" do
      expect(Softcover::Commands::Generator.verify!).to be_true
    end

    describe "book.yml" do
      subject(:yml) { YAML.load_file(File.join name, 'config', 'book.yml') }

      it "should have the right title" do
        expect(yml['title']).to eq "Title of the Book"
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
        expect { `softcover build` }.not_to raise_error
      end

      it "should have chapter files" do
        expect('chapters/a_chapter.tex').to exist
        expect('chapters/another_chapter.tex').to exist
      end

      it "should have Book.txt" do
        expect(Softcover::BookManifest::TXT_PATH).to exist
      end

      it "should not have the markdown files" do
        expect('chapters/a_chapter.md').not_to exist
      end

      it "should have a README" do
        expect('README.md').to exist
      end

      describe ".gitignore" do
        subject { File.read('.gitignore') }

        it { should match(/\*\.aux/) }
        it { should match(/\*\.log/) }
        it { should match(/\*\.toc/) }
        it { should match(/\*\.tmp\.\*/) }
        it { should match(/html\//) }
        it { should match(/epub\//) }
        it { should match(/ebooks\//) }
        it { should match(/screencasts\//) }
        it { should match(/log\//) }
        it { should match(/\.DS_Store/) }
      end

      describe "deployment configuration" do
        subject { File.read(Softcover::Commands::Deployment.deploy_config) }

        it { should match /^# softcover build:all/ }
        it { should match /^# softcover build:preview/ }
        it { should match /^# softcover publish/ }
      end

      describe "CSS" do

        let(:css_file) { 'html/stylesheets/softcover.css' }
        let(:custom_css) { 'html/stylesheets/custom.css' }

        it "should have the right CSS file" do
          expect(css_file).to exist
        end

        it "should have a custom CSS file" do
          expect(custom_css).to exist
        end
      end

      describe "styles" do

        it "should have a right style file" do
          style = File.join(Softcover::Directories::STYLES, 'softcover.sty')
          expect(style).to exist
        end
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
end
