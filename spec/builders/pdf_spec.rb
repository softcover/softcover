require 'spec_helper'

describe Polytexnic::Builders::Pdf do

  context "for a PolyTeX book" do
    before(:all) do
      generate_book
      @builder = Polytexnic::Builders::Pdf.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { Polytexnic::Builders::Pdf.new }

    describe "#build!" do

      it "should create a tmp LaTeX file" do
        expect(Polytexnic::Utils.tmpify('book.tex')).to exist
      end

      it "should create tmp files for all chapters" do
        builder.manifest.chapter_file_paths.each do |filename|
          expect(Polytexnic::Utils.tmpify(filename)).to exist
        end
      end

      it "should replace the main file's \\includes with tmp files" do
        contents = File.read(Polytexnic::Utils.tmpify('book.tex'))
        builder.manifest.pdf_chapters.each do |chapter|
          expect(contents).to match("\\include{chapters/#{chapter.slug}.tmp}")
        end
      end

      it "should build a PDF" do
        expect('ebooks/book.pdf').to exist
      end

      it "should create a Pygments style file" do
        expect('pygments.sty').to exist
      end

      it "should write the correct PolyTeXnic commands file" do
        expect(File.read('polytexnic_commands.sty')).to match /newcommand/
      end
    end
  end

  context "for a Markdown book" do
    before(:all) do
      generate_book(markdown: true)
      @builder = Polytexnic::Builders::Pdf.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { Polytexnic::Builders::Pdf.new }

    describe "#build!" do

      it "should create a tmp LaTeX file" do
        expect(Polytexnic::Utils.tmpify('book.tex')).to exist
      end
    end
  end
end

