require 'spec_helper'

describe Polytexnic::CLI do

	subject { capture(:stdout) { Polytexnic::CLI.start commands } } 

	context 'help output' do
		let(:commands) { ['help'] }

		%w{new login logout publish build}.each do |cmd|
			it { should =~ /#{cmd}/ }
		end

		Polytexnic::FORMATS.each do |format|
			it { should =~ /build:#{format}/ }
		end
	end
end
