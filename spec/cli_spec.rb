require 'spec_helper'

describe Softcover::CLI do

  context 'help output' do
    subject { capture(:stdout) { Softcover::CLI.start commands } }

    let(:commands) { ['help'] }

    %w{new login logout publish build server}.each do |cmd|
      it { should match /#{cmd}/ }
    end

    Softcover::FORMATS.each do |format|
      it { should match /build:#{format}/ }
      it { should match /Build #{format.upcase}/ }
    end
    it { should match /build:all/ }
    it { should match /build:preview/ }
    it { should match /epub:validate/ }
    it { should match /epub:check/ }
  end

  context "version number" do
    subject { `softcover -v` }
    it { should eq "Softcover #{Softcover::VERSION}\n" }
  end

  context "softcover build:pdf options" do
    subject { `softcover help build:pdf` }
    it { should include '-d, [--debug]' }
    it { should include '-o, [--once]' }
    it { should include 'f, [--find-overfull]' }
  end

  context "softcover build:epub options" do
    subject { `softcover help build:epub` }
    it { should include '-q, [--quiet]' }
    it { should include '-s, [--silent]' }
  end

  context "softcover build:mobi options" do
    subject { `softcover help build:mobi` }
    it { should include '-q, [--quiet]' }
    it { should include '-s, [--silent]' }
    it { should include '-k, [--kindlegen]' }
    it { should include '-a, [--amazon]' }
  end

  context "softcover new options" do
    subject { `softcover help new` }
    it { should include '-p, [--polytex]' }
    it { should include '-a, [--article]' }
  end

  context "softcover new" do
    before(:all) { chdir_to_fixtures }
    after(:all)  { remove_book }
    it "should not raise error" do
      result = `softcover new book &> /dev/null`
      expect($?.exitstatus).to eq 0
    end
  end

  context "softcover clean" do
    before do
      chdir_to_fixtures

      FileUtils.touch('foo.aux')
      FileUtils.touch('foo.toc')
      FileUtils.touch('foo.out')
      FileUtils.touch('foo.tmp.pdf')
      FileUtils.touch('.highlight_cache')
    end

    it "should remove unnecessary files" do
      `softcover clean`
      expect('foo.aux').not_to exist
      expect('foo.aux').not_to exist
      expect('foo.toc').not_to exist
      expect('foo.out').not_to exist
      expect('foo.tmp.pdf').not_to exist
      expect('.highlight_cache').not_to exist
    end
  end

  shared_examples "book" do
    context "pdf" do

      context "without options" do
        before { silence { `softcover build:pdf` } }
        it "should generate the PDF" do
          expect(path('ebooks/book.pdf')).to exist
        end
      end

      context "with the debug option" do
        before { silence { `softcover build:pdf -d` } }
        it "should generate the debug PDF" do
          expect(path('book.pdf')).to exist
        end
      end

      context "with the --once option" do
        it "should build without error" do
          expect { silence { `softcover build:pdf --once` } }.not_to raise_error
        end
      end

      context "with the --find-overfull option" do
        it "should not find any overfull lines" do
          expect(`softcover build:pdf --find-overfull`.strip).to be_empty
        end
      end
    end

    context "html" do

      context "without options" do
        before { silence { `softcover build:html` } }

        it "should generate the html" do
          expect(path('html/book.html')).to exist
        end
      end
    end

    context "epub & mobi" do

      context "without options" do
        before { silence { `softcover build:mobi` } }

        it "should generate the EPUB & MOBI" do
          expect(path('ebooks/book.epub')).to exist
          expect(path('ebooks/book.mobi')).to exist
        end
      end

      context "command-line options" do
        subject(:options) { `softcover help build:mobi` }
        it { should_not include 'calibre' }
        it { should     include 'kindlegen' }
      end
    end
  end

  describe "PolyTeX books" do

    before(:all) do
      remove_book
      chdir_to_fixtures
      silence { `softcover new book --polytex` }
      chdir_to_book
    end
    after(:all) { remove_book }

    it_should_behave_like "book"
  end

  describe "Markdown books" do

    before(:all) do
      remove_book
      chdir_to_fixtures
      silence { `softcover new book` }
      chdir_to_book
    end
    after(:all) { remove_book }

    it_should_behave_like "book"
  end

  describe "stubbed commands" do

    context "unpublish" do
      before { Softcover::Utils.stub(:source).and_return(:markdown) }
      it "should have the right slug" do
        Softcover::BookManifest.should_receive(:new).with(origin: :markdown)
                               .and_return(OpenStruct.new(slug: ""))
        Softcover::Utils.unpublish_slug
      end
    end


    context "open" do
      before { Softcover::Utils.stub(:source).and_return(:markdown) }
      it "should have the right book" do
        Softcover::Book.should_receive(:new).with(origin: :markdown)
        Softcover::Commands::Opener::book
      end
    end
  end

  describe "check" do
    subject { `softcover check` }
    it { should match /all dependencies satisfied/i }
  end
end
