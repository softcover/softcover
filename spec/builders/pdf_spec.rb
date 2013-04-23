require 'spec_helper'

describe Polytexnic::Builders::Pdf do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  describe "#build!" do
    subject(:builder) { Polytexnic::Builders::Pdf.new }
    before { builder.build! }

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
      builder.manifest.chapters.each do |chapter|
        expect(contents).to match("\\include{chapters/#{chapter.slug}.tmp}")
      end
    end

    it "should build a PDF" do
      expect('book.pdf').to exist
    end

    it "should create a Pygments style file" do
      expect('pygments.sty').to exist
      expect('pygments.sty').to exist
    end

  end
end

