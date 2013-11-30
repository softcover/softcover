require 'spec_helper'

describe Softcover::BookManifest do
  context "with book generation" do
    before(:all) { generate_book }
    after(:all)  { remove_book }
    subject(:manifest) { Softcover::BookManifest.new }

    context "in valid book directory" do

      describe "basic information" do
        its(:title) { should eq "Title of the Book" }
        its(:subtitle) { should eq "Change me" }
        its(:description) { should eq "Change me." }
        its(:cover) { should eq "images/cover.png" }
        its(:author) { should eq "Author Name" }
      end

      describe "chapter information" do
        subject(:chapter) { manifest.chapters[1] }
        it { should be_a Softcover::BookManifest::Chapter }
        its(:title) { should eq "A chapter" }
        its(:slug) { should eq "a_chapter" }
        its(:chapter_number) { should eq 1 }
        its("sections.first.name") do
          should eq 'A section'
        end

        describe "for second chapter" do
          subject(:chapter) { manifest.chapters[2] }
          its(:title) { should eq 'Another chapter' }
          its(:slug) { should eq "another_chapter" }
          its(:chapter_number) { should eq 2 }
        end

        describe "for third chapter" do
          subject(:chapter) { manifest.chapters[3] }
          its(:title) { should eq 'Yet \emph{another} chapter' }
          its(:slug) { should eq "yet_another_chapter" }
          its(:chapter_number) { should eq 3 }
        end
      end
    end

    context "in a valid book subdirectory" do
      before { Dir.chdir 'chapters' }
      describe "finding the manifest in a higher directory" do
        its(:slug) { should eq "book" }
      end
    end


    context "with mixed Markdown & PolyTeX files" do
      before do
        manifest.stub(:source_files).and_return(['foo.md', 'bar.tex'])
      end

      it "should have the right basenames" do
        expect(manifest.basenames).to eq ['foo', 'bar']
      end

      it "should have the right extensions" do
        expect(manifest.extensions).to eq ['.md', '.tex']
      end

      it "should have the right chapter objects" do
        expect(manifest.chapter_objects[0].slug).     to eq 'foo'
        expect(manifest.chapter_objects[0].extension).to eq '.md'
        expect(manifest.chapter_objects[1].slug).     to eq 'bar'
        expect(manifest.chapter_objects[1].extension).to eq '.tex'
      end
    end
  end

  context "in an invalid book directory" do
    it "raises an error when manifest missing" do
      expect{ subject }.to raise_error(Softcover::BookManifest::NotFound)
    end
  end
end
