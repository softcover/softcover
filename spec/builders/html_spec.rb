require 'spec_helper'

describe Polytexnic::Builders::Html do

  describe "when generating from PolyTeX source" do
    before(:all) { generate_book }
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }
      let(:file_to_be_removed) { path('html/should_be_removed.html') }
      before do
        # Create an empty file that should be removed automatically.
        File.write(file_to_be_removed, '')
        builder.build!
      end

      its(:built_files) { should include File.join('html', 'book.html') }

      it "should remove the HTML file without a corresponding LaTeX file" do
        expect(file_to_be_removed).not_to exist
      end

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

      describe "frontmatter output" do
        let(:filename) { 'html/frontmatter_fragment.html' }

        it "should create a frontmatter file" do
          expect(filename).to exist
        end

        describe "contents" do
          subject(:html) { Nokogiri::HTML(File.open(filename)) }

          it "should include the title page" do
            expect(html.at_css('div#title_page')).not_to be_nil
          end

          it "should include the table of contents" do
            expect(html.at_css('div#table_of_contents')).not_to be_nil
          end
        end
      end

      describe "HTML MathJax output" do
        let(:output) { File.read(path('html/a_chapter.html')) }
        subject { output }

        it { should match 'MathJax.Hub.Config' }
        it { should match 'TeX-AMS-MML_SVG' }
        it { should match 'Lorem ipsum' }
      end
    end
  end

  describe "when generating from Markdown source" do
    before(:all) do
      generate_book(markdown: true)
      @file_to_be_removed = path('chapters/should_be_removed.tex')
      File.write(@file_to_be_removed, '')
    end
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }

      before { builder.build! }

      its(:built_files) { should include "html/a_chapter.html" }
      its(:built_files) { should include "html/a_chapter_fragment.html" }
      its(:built_files) { should include "html/another_chapter.html" }
      its(:built_files) { should include "html/another_chapter_fragment.html" }

      it "should remove an unneeded LaTeX file" do
        expect(@file_to_be_removed).not_to exist
      end

      describe "master LaTeX file" do
        let(:master_file) { Dir['*.tex'].reject { |f| f =~ /\.tmp/}.first }
        subject { File.read(master_file) }
        it { should include '\include{chapters/preface}' }
        it { should include '\include{chapters/a_chapter}' }
        it { should include '\include{chapters/another_chapter}' }
        it { should include '\include{chapters/yet_another_chapter}' }
        it { should include '\end{document}' }
      end
    end
  end
end
