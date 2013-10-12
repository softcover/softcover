require 'spec_helper'

describe Polytexnic::CLI do

  context 'help output' do
    subject { capture(:stdout) { Polytexnic::CLI.start commands } }

    let(:commands) { ['help'] }

    %w{new login logout publish build server}.each do |cmd|
      it { should match /#{cmd}/ }
    end

    Polytexnic::FORMATS.each do |format|
      it { should match /build:#{format}/ }
      it { should match /Build #{format.upcase}/ }
    end
    it { should match /build:all/ }
    it { should match /build:preview/ }
    it { should match /epub:validate/ }
    it { should match /epub:check/ }
  end

  context "poly new options" do
    subject(:output) { `poly help new` }
    it { should include '-m, [--markdown]' }
    it { should include '-s, [--simple]' }
  end

  context "poly new" do
    before(:all) { chdir_to_fixtures }
    after(:all) { remove_book }
    it "should not raise error" do
      result = `poly new book 2>&1`
      expect($?.exitstatus).to eq 0
    end
  end
end
