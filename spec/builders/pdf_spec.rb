require 'spec_helper'

describe Polytexnic::Builders::Pdf do
  context "in valid TeX directory" do
    before do
      chdir_to_book
      delete_files_matching('*.tmp.tex')
      delete_files_matching('chapters/*.tmp.tex')
      File.delete('book.pdf') if File.exist?('book.pdf')
    end

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Pdf.new }
      before { builder.build! }

      it "should be create a tmp LaTeX file" do
        expect('book.tmp.tex').to exist
      end

      it "should build a PDF" do
        expect('book.pdf').to exist
      end
    end
  end
end

# Delete the files matching a particular pattern.
# E.g., delete_files_matching('*.aux') removes all LaTeX auxiliary files.
def delete_files_matching(pattern)
  Dir.glob(pattern).each { |file| File.delete(file) }
end