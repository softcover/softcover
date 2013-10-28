require 'spec_helper'

describe Polytexnic::BookManifest do
  context "with book generation" do
    before(:all) { generate_book }
    after(:all)  { remove_book }
    subject(:manifest) { Polytexnic::BookManifest.new }

    context "in valid book directory" do

      describe "basic information" do
        its(:title) { should eq "book" }
        its(:subtitle) { should eq "Change-me" }
        its(:description) { should eq "Change me." }
        its(:cover) { should eq "images/change-me.png" }
        its(:author) { should eq "Author Name" }
      end

      describe "chapter information" do
        subject(:chapter) { manifest.chapters[1] }
        it { should be_a Polytexnic::BookManifest::Chapter }
        its(:title) { should eq "Lorem ipsum" }
        its(:slug) { should eq "a_chapter" }
        its(:chapter_number) { should eq 1 }
        its("sections.first.name") do
          should eq '\emph{Bacon} ipsum'
        end

        describe "for last chapter" do
          subject(:chapter) { manifest.chapters.last }
          its(:title) { should eq 'Foo \emph{bar}' }
          its(:slug) { should eq "another_chapter" }
          its(:chapter_number) { should eq 2 }
        end
      end
    end

    context "in a valid book subdirectory" do
      before { Dir.chdir 'chapters' }
      describe "finding the manifest in a higher directory" do
        its(:title) { should eq "book" }
      end
    end
  end

  context "in an invalid book directory" do
    it "raises an error when manifest missing" do
      expect{ subject }.to raise_error(Polytexnic::BookManifest::NotFound)
    end
  end
end