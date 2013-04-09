require 'spec_helper'

describe Polytexnic::Builders::Pdf do
  context "in valid TeX directory" do
    before do
      chdir_to_book
      clean!
    end

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
        contents = File.open(Polytexnic::Utils.tmpify('book.tex')).read
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
end


# Cleans the fixtures directory as a prep for testing.
def clean!
  delete_files_matching('*.tmp.tex')
  delete_files_matching('chapters/*.tmp.tex')
  File.delete('book.pdf') if File.exist?('book.pdf')
  File.delete('pygments.sty') if File.exist?('pygments.sty')
end

# Deletes the files matching a particular pattern.
# E.g., delete_files_matching('*.aux') removes all LaTeX auxiliary files.
def delete_files_matching(pattern)
  Dir.glob(pattern).each { |file| File.delete(file) }
end

