require 'spec_helper'

# NOTE: these specs hang on Travis
# return if ENV['CI']

describe Softcover::Builders::Pdf do

  context "for a PolyTeX book" do
    before(:all) do
      generate_book
      @builder = Softcover::Builders::Pdf.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { Softcover::Builders::Pdf.new }

    describe "#build!" do

      it "should create a tmp LaTeX file" do
        expect(Softcover::Utils.tmpify(builder.manifest, 'book.tex')).to exist
      end

      it "should create tmp files for all chapters" do
        builder.manifest.chapter_file_paths.each do |filename|
          expect(Softcover::Utils.tmpify(builder.manifest, filename)).to exist
        end
      end

      context "preamble" do
        subject(:preamble_file) { File.join('config', 'preamble.tex') }
        it { should exist }
        context "content" do
          subject { Softcover::Utils::master_latex_header(builder.manifest) }
          it { should include File.read(preamble_file) }
          it { should include '\usepackage{latex_styles/softcover}' }
          it { should include "\\title{#{builder.manifest.title}}" }
          it { should include "\\author{#{builder.manifest.author}}" }
          it { should include "\\date{#{builder.manifest.date}}" }
        end
      end

      it "should prepend the fontsize verbatim declaration for source code" do
        fontsize = '\begin{Verbatim}[fontsize=\relsize'
        expect(File.read(File.join('tmp', 'a_chapter.tmp.tex'))).to include fontsize
      end

      it "should replace the main file's \\includes with tmp files" do
        contents = File.read(Softcover::Utils.tmpify(builder.manifest,
                                                     'book.tex'))
        builder.manifest.pdf_chapter_names.each do |name|
          expect(contents).to match("\\include{tmp/#{name}.tmp}")
        end
      end

      it "should build a PDF" do
        expect('ebooks/book.pdf').to exist
      end

      it "should create a Pygments style file" do
        pygments = File.join(Softcover::Directories::STYLES, 'pygments.sty')
        expect(pygments).to exist
      end

      it "should write the correct PolyTeXnic commands file" do
        styles = File.join(Softcover::Directories::STYLES,
                           'polytexnic_commands.sty')
        expect(File.read(styles)).to match /newcommand/
      end

      context "language customization file" do
        subject { File.join(Softcover::Directories::STYLES,
                            'language_customization.sty') }
        it { should exist }
      end

      context "after removing Book.txt" do
        before { FileUtils.rm Softcover::BookManifest::TXT_PATH }
        it "should still build the book" do
          expect(Softcover::BookManifest::TXT_PATH).not_to exist
          expect { @builder.build! }.not_to raise_error
        end
      end
    end
  end

  context "for a Markdown book" do
    before(:all) do
      generate_book(markdown: true)
      @builder = Softcover::Builders::Pdf.new
      @builder.build!
      chdir_to_book
    end
    after(:all) { remove_book }
    subject(:builder) { Softcover::Builders::Pdf.new }

    describe "#build!" do

      it "should create a tmp LaTeX file" do
        expect(Softcover::Utils.tmpify(builder.manifest, 'book.tex')).to exist
      end

      describe "LaTeX file" do
        subject(:content) do
          File.read(Softcover::Utils.tmpify(builder.manifest, 'book.tex'))
        end
        it { should_not be_empty }
        it { should include '\includepdf{images/cover.pdf}' }
        it { should include '\maketitle' }
        it { should include '\tableofcontents' }
        it { should include '\include{tmp/a_chapter.tmp}' }
      end
    end
  end
end

