require 'spec_helper'

describe Polytexnic::Book do
  context "#initialize" do
    context "valid book directory" do
      before(:all) { generate_book }
      after(:all)  { remove_book }

      # disabling these tests for now:
      # its(:filenames) { should_not include "html/test-book.html"}
      # its(:filenames) { should_not include "html/test-book_fragment.html"}

      # its(:filenames) { should include "html/chapter-1_fragment.html"}
      # its(:filenames) { should_not include "html/chapter-1.html"}

      # its(:filenames) { should include "book.mobi"}
      # its(:filenames) { should include "book.epub"}
      # its(:filenames) { should include "book.pdf"}

      its(:slug) { should eq "book" }
    end

    # context "valid md book directory" do
    #   before { chdir_to_md_book }

    #   its(:slug) { should eq "md-book" }
    # end
  end

  context "#create" do

  end
end