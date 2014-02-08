require 'spec_helper'

describe Softcover::Commands::Build do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  context 'valid builder formats' do
    Softcover::FORMATS.each do |format|
      subject { Softcover::Commands::Build.builder_for(format) }
      it { should be_a Softcover::Builder }
    end
  end

  context 'invalid builder format' do
    subject { lambda { Softcover::Commands::Build.for_format('derp') } }

    it { should raise_error }
  end

  context 'building all' do
    subject(:build) { Softcover::Commands::Build }

    it { should respond_to(:all_formats) }
    it "should build all formats" do
      pdf_builder  = build.builder_for('pdf')
      mobi_builder = build.builder_for('mobi')

      pdf_builder .should_receive(:build!)
      mobi_builder.should_receive(:build!)

      build.should_receive(:builder_for).with('pdf') .and_return(pdf_builder)
      build.should_receive(:builder_for).with('mobi').and_return(mobi_builder)

      build.all_formats
    end
  end

  context 'building previews' do
    subject(:build) { Softcover::Commands::Build }

    it { should respond_to(:preview) }
    it "should build previews" do
      preview_builder = build.builder_for('preview')
      preview_builder.should_receive(:build!)
      build.should_receive(:builder_for).with('preview').
                                         and_return(preview_builder)
      build.preview
    end
  end

  describe "commands helper" do
    let(:lines) { ['foo', ' #  bar', 'baz'] }
    subject { Softcover::Commands::Build.commands(lines) }

    it { should match /foo/ }
    it { should_not match /bar/ }
    it { should match /baz/ }
  end
end