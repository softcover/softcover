require 'spec_helper'

describe Polytexnic::BookManifest do
  context "in valid book directory" do
    before { chdir_to_book }

    its(:title) { should eq "Test Book" }
    its(:subtitle) { should eq "Sub Title" }
    its(:description) { should eq "Book description" }
    its(:cover) { should eq "images/1.png" }

    its("chapters.first") { should be_a Polytexnic::BookManifest::Chapter }
    its("chapters.first.title") { should eq "Chapter 1" }
    its("chapters.first.slug") { should eq "chapter-1" }
    its("chapters.first.chapter_number") { should eq 1 }
    its("chapters.first.sections.first") { should eq 'Section 1a' }
    its("chapters.first.sections.last") { should eq 'Section 1b' }

    its("chapters.last.title") { should eq "Chapter 2 Long Title" }
    its("chapters.last.slug") { should eq "chapter-2" }
    its("chapters.last.chapter_number") { should eq 2 }
    its("chapters.last.sections.first") { should eq 'Section 2a' }
    its("chapters.last.sections.last") { should eq 'Section 2b' }
  end
end