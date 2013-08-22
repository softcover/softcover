require 'spec_helper'

describe Polytexnic::Builders::Html do

  describe "when generating from PolyTeX sourde" do
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

  describe "when generating from Markdown source" do
    before(:all) { generate_book(source: :markdown) }
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }

      before { builder.build! }

      its(:built_files) { should include "html/a_chapter.html" }
      its(:built_files) { should include "html/a_chapter_fragment.html" }
      its(:built_files) { should include "html/another_chapter.html" }
      its(:built_files) { should include "html/another_chapter_fragment.html" }

      describe "master LaTeX file" do
        let(:master_file) { Dir['*.tex'].reject { |f| f =~ /\.tmp/}.first }
        subject { File.read(master_file) }
        it { should include '  \include{chapters/a_chapter}' }
        it { should include '  \include{chapters/another_chapter}' }
        it { should include '  \include{chapters/yet_another_chapter}' }
        it { should include '\end{document}' }
      end
    end
  end
end
