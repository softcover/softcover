require 'spec_helper'

describe Softcover::Builders::Html do

  describe "when generating from PolyTeX source" do
    before(:all) { generate_book }
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Softcover::Builders::Html.new }
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

        it { should include '<!DOCTYPE html>' }
        it { should include 'pygments.css' }
        it { should include 'MathJax' }
        it { should_not include 'functionNumber'}

        context "HTML document" do
          subject(:doc) { Nokogiri::HTML(output) }

          context "frontmatter" do
            subject(:frontmatter) { doc.at_css('#frontmatter') }
            it { should_not be_nil }
            it "should link the preface to the frontmatter page" do
              link = '<a href="#preface"'
              expect(frontmatter.to_xhtml).to match /#{link}/
            end
          end

          context "first chapter" do
            subject(:chapter) { doc.at_css('#cha-a_chapter') }
            it { should_not be_nil }
            it "should have a chapter class" do
              expect(chapter['class']).to eq 'chapter'
            end
          end

          context "second chapter" do
            subject(:chapter) { doc.at_css('#cha-another_chapter') }
            it { should_not be_nil }
            it "should have a chapter class" do
              expect(chapter['class']).to eq 'chapter'
            end
          end
        end
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

        it { should match('A chapter') }
      end

      describe "frontmatter output" do
        let(:filename) { 'html/frontmatter_fragment.html' }

        it "should create a frontmatter file" do
          expect(filename).to exist
        end

        describe "contents" do
          subject(:doc) { Nokogiri::HTML(File.open(filename)) }

          it "should include the title page" do
            expect(doc.at_css('div#title_page')).not_to be_nil
          end

          it "should include the table of contents" do
            expect(doc.at_css('div#table_of_contents')).not_to be_nil
          end
        end
      end

      describe "HTML MathJax output" do
        let(:output) { File.read(path('html/a_chapter.html')) }
        subject { output }

        it { should include 'MathJax.Hub.Config' }
        it { should include 'TeX-AMS-MML_SVG' }
        it { should include 'formatNumber: function (n)' }
        it { should include 'A chapter' }
      end
    end
  end

  describe "when generating from Markdown source" do
    before(:all) do
      generate_book(markdown: true)
    end
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Softcover::Builders::Html.new }

      before do
        @file_to_be_removed = path("#{builder.manifest.polytex_dir}/remove.tex")
        File.write(@file_to_be_removed, '')
        builder.build!
      end

      its(:built_files) { should include "html/a_chapter.html" }
      its(:built_files) { should include "html/a_chapter_fragment.html" }
      its(:built_files) { should include "html/another_chapter.html" }
      its(:built_files) { should include "html/another_chapter_fragment.html" }

      it "should remove an unneeded LaTeX file" do
        expect(@file_to_be_removed).not_to exist
      end

      it "should include generated LaTeX files" do
        expect(Dir.glob(path('generated_polytex/*.tex'))).not_to be_empty
      end

      it "should write cache files" do
        expect(Dir.glob(path('tmp/*.cache'))).not_to be_empty
      end

      describe "master LaTeX file" do
        let(:master_file) { builder.master_filename(builder.manifest) }
        subject { File.read(master_file) }
        it { should include "\\title{#{builder.manifest.title}}" }
        it { should include "\\subtitle{#{builder.manifest.subtitle}}" }
        it { should include "\\author{#{builder.manifest.author}}" }
        it { should include '\date{}' }
        it { should include '\begin{document}' }
        it { should include '\include{generated_polytex/preface}' }
        it { should include '\include{generated_polytex/a_chapter}' }
        it { should include '\include{generated_polytex/another_chapter}' }
        it { should include '\include{generated_polytex/yet_another_chapter}' }
        it { should include '\end{document}' }
      end

      describe "commented-out lines of Book.txt" do
        let(:lines) { ['foo.md', '# bar.md'] }
        let(:content) { builder.master_content(builder.manifest) }
        before { builder.stub(:book_file_lines).and_return(lines) }
        it "should be ignored" do
          expect(content).to     include 'generated_polytex/foo'
          expect(content).not_to include 'generated_polytex/bar'
        end
      end
    end
  end

  describe "when making an article" do
    before(:all) do
      generate_book(markdown: true, article: true)
    end
    after(:all)  { remove_book }

    describe "#build!" do
      subject(:builder) { Softcover::Builders::Html.new }

      before do
        @file_to_be_removed = path("#{builder.manifest.polytex_dir}/remove.tex")
        File.write(@file_to_be_removed, '')
        builder.build!
      end

      let(:html_file) { path("html/an_article.html") }

      its(:built_files) { should include html_file }
      its(:built_files) { should include path("html/an_article_fragment.html") }
      its(:built_files) { should_not include path("html/another_chapter.html") }

      describe "article html" do
        subject { File.read(html_file) }
        it { should include builder.manifest.title }
      end

      describe "master LaTeX file" do
        let(:master_file) { builder.master_filename(builder.manifest) }
        subject { File.read(master_file) }
        it { should include '{extarticle}' }
        it { should include "\\title{#{builder.manifest.title}}" }
        it { should include "\\subtitle{#{builder.manifest.subtitle}}" }
        it { should include "\\author{#{builder.manifest.author}}" }
        it { should include '\date{}' }
        it { should include '\begin{document}' }
        it { should include '\include{generated_polytex/an_article}' }
        it { should include '\end{document}' }
      end
    end
  end
end
