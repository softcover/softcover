require 'spec_helper'

describe Polytexnic::Book do
  context "#initialize" do

    before { chdir_to_book }

    subject { Polytexnic::Book.new }

    its(:files) { should_not include "html/test-book.html"}
    its(:files) { should_not include "html/test-book_fragment.html"}

    its(:files) { should include "html/chapter-1_fragment.html"}
    its(:files) { should_not include "html/chapter-1.html"}

    its(:files) { should include "test-book.mobi"}
    its(:files) { should include "test-book.epub"}
    its(:files) { should include "test-book.pdf"}

    its(:slug) { should eq "test-book" }
  end
end