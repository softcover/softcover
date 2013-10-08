require 'spec_helper'

describe Polytexnic::Commands::Build do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  context 'valid builder formats' do
    Polytexnic::FORMATS.each do |format|
      subject { Polytexnic::Commands::Build.builder_for(format) }
      it { should be_a Polytexnic::Builder }
    end
  end

  context 'invalid builder format' do
    subject { lambda { Polytexnic::Commands::Build.for_format('derp') } }

    it { should raise_error }
  end

  context 'building all' do
    subject(:build) { Polytexnic::Commands::Build }

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
end