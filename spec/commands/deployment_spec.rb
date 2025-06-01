require 'spec_helper'

describe Softcover::Commands::Deployment do

  describe "default commands" do
    before { allow(Softcover::Commands::Deployment).to receive(:article?).and_return(false) }
    subject { Softcover::Commands::Deployment.default_commands }

    it { should match /softcover build:all/ }
    it { should match /softcover build:preview/ }
    it { should match /softcover publish/ }
  end

  describe "commands helper" do
    let(:lines) { ['foo', ' #  bar', 'baz'] }
    subject { Softcover::Commands::Deployment.commands(lines) }

    it { should match /foo/ }
    it { should_not match /bar/ }
    it { should match /baz/ }
  end
end