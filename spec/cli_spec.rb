require 'spec_helper'

describe Polytexnic::CLI do

  context 'help output' do
    subject { capture(:stdout) { Polytexnic::CLI.start commands } }

    let(:commands) { ['help'] }

    %w{new login logout publish build}.each do |cmd|
      it { should =~ /#{cmd}/ }
    end

    Polytexnic::FORMATS.each do |format|
      it { should =~ /build:#{format}/ }
    end

    it { should =~ /epub:validate/ }
  end
end
