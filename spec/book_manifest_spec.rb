require 'spec_helper'

describe Polytexnic::BookManifest do
  context "in valid book directory" do
    before(:all) { generate_book }
    after(:all)  { remove_book }

    describe "basic information" do
      its(:title) { should eq "book" }
      its(:subtitle) { should eq "Change-me" }
      its(:description) { should eq "Change me." }
      its(:cover) { should eq "images/change-me.png" }
      its(:author) { should eq "Author Name" }
    end

    describe "chapter information" do
      its("chapters.first") { should be_a Polytexnic::BookManifest::Chapter }
      its("chapters.first.title") { should eq "Lorem ipsum" }
      its("chapters.first.slug") { should eq "a_chapter" }
      its("chapters.first.chapter_number") { should eq 1 }
      its("chapters.first.sections.first.name") do
        should eq '\emph{Bacon} ipsum'
      end

      its("chapters.last.title") { should eq 'Foo \emph{bar}' }
      its("chapters.last.slug") { should eq "another_chapter" }
      its("chapters.last.chapter_number") { should eq 2 }
    end
  end
end