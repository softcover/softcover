require 'spec_helper'

describe Polytexnic::Book do
  context "#initialize" do
    context "valid book directory" do
      before(:all) { generate_book(id: 1) }
      after(:all)  { remove_book }

      # disabling these tests for now:
      its(:filenames) { should_not include "html/test-book.html"}

      its(:filenames) { should include "html/chapter-1_fragment.html"}
      its(:filenames) { should_not include "html/chapter-1.html"}

      its(:filenames) { should include "ebooks/test-book.mobi"}
      its(:filenames) { should include "ebooks/test-book.epub"}
      its(:filenames) { should include "ebooks/test-book.pdf"}

      its(:slug) { should eq "book" }
      its(:url) { should match /\/books\/(.*?)\/redirect/ }

      it "sets chapter attributes" do
        expect(subject.chapter_attributes.first[:menu_heading]).
          to match /Frontmatter/
      end

      it "has rendered latex in menu_heading" do
        expect(subject.chapter_attributes.last[:menu_heading]).
          to match /<em>/
      end
    end
  end
end