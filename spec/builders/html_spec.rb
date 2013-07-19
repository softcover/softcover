require 'spec_helper'

describe Polytexnic::Builders::Html do

  context "in valid TeX directory" do
    before(:all) { generate_book }
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }
      before { builder.build! }

      its(:built_files) { should include "html/book.html" }

      describe "HTML output" do
        let(:output) { File.read("html/book.html") }
        subject { output }

        it { should match('<!DOCTYPE html>') }
        it { should match('pygments.css') }
        it { should match('<div id=\"cha-lorem_ipsum\" ' +
                          'data-tralics-id=\"cid1\"' +
                          ' class=\"chapter\" data-number=\"1\">') }

      end

      describe "Pygments stylesheet" do
        let(:stylesheet) { 'html/stylesheets/pygments.css' }
        subject { stylesheet }

        it { should exist }
        it "should have a .highlight class" do
          expect(File.read(stylesheet)).to match('.highlight')
        end
      end

      describe "HTML fragments output" do
        let(:output) { File.read('html/a_chapter_fragment.html') }
        subject { output }

        it { should match('Lorem ipsum') }
      end

      describe "HTML MathJax output" do
        let(:output) { File.read('html/a_chapter.html') }
        subject { output }

        it { should match 'MathJax.Hub.Config' }
        it { should match 'TeX-AMS-MML_SVG' }
        it { should match 'Lorem ipsum' }
      end
    end
  end

  context "in valid MD directory" do
    before { chdir_to_md_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }

      before { builder.build! }

      2.times do |i|
        its(:built_files) { should include "html/chapter#{i+1}.html" }
        its(:built_files) { should include "html/chapter#{i+1}_fragment.html" }
      end

      after(:all) do
        chdir_to_md_book
        builder.clean!
      end
    end
  end
end