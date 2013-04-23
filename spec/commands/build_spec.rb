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

  context 'building each format' do
    Polytexnic::FORMATS.each do |format|
      subject {
        lambda {
          silence { Polytexnic::Commands::Build.for_format format }
        }
      }

      it { should_not raise_error }
    end
  end

  context 'building all' do
    subject {
      lambda {
        silence { Polytexnic::Commands::Build.all_formats }
      }
    }

    it { should_not raise_error }

    after(:all) do
      chdir_to_md_book
      Polytexnic::Builders::Html.new.clean!
    end
  end
end