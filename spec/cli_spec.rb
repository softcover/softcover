require 'spec_helper'

describe Polytexnic::CLI do

  context 'help output' do
    subject { capture(:stdout) { Polytexnic::CLI.start commands } }

    let(:commands) { ['help'] }

    %w{new login logout publish build server}.each do |cmd|
      it { should match /#{cmd}/ }
    end

    Polytexnic::FORMATS.each do |format|
      it { should match /build:#{format}/ }
      it { should match /Build #{format.upcase}/ }
    end
    it { should match /build:all/ }
    it { should match /build:preview/ }
    it { should match /epub:validate/ }
    it { should match /epub:check/ }
  end

  context "poly build:pdf options" do
    subject { `poly help build:pdf` }
    it { should include '-d, [--debug]' }
  end

  context "poly new options" do
    subject { `poly help new` }
    it { should include '-m, [--markdown]' }
    it { should include '-s, [--simple]' }
  end

  context "poly new" do
    before(:all) { chdir_to_fixtures }
    after(:all) { remove_book }
    it "should not raise error" do
      result = `poly new book 2>&1`
      expect($?.exitstatus).to eq 0
    end
  end

  shared_examples "book" do
    context "pdf" do

      context "without options" do
        before { silence { `poly build:pdf` } }
        it "should generate the PDF" do
          expect(path('ebooks/book.pdf')).to exist
        end
      end

      context "with the debug option" do
        before { silence { `poly build:pdf -d` } }
        it "should generate the debug PDF" do
          expect(path('book.pdf')).to exist
        end
      end
    end

    context "epub & mobi" do

      context "without options" do
        before { silence { `poly build:mobi` } }

        it "should generate the EPUB & MOBI" do
          expect(path('ebooks/book.epub')).to exist
          expect(path('ebooks/book.mobi')).to exist
        end
      end
    end
  end

  describe "PolyTeX books" do

    before(:all) do
      chdir_to_fixtures
      silence { `poly new book` }
      chdir_to_book
    end
    after(:all) { remove_book }

    it_should_behave_like "book"
  end

  describe "Markdown books" do

    before(:all) do
      chdir_to_fixtures
      silence { `poly new book -m` }
      chdir_to_book
    end
    after(:all) { remove_book }

    it_should_behave_like "book"
  end
end
