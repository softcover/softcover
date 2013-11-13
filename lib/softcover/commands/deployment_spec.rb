require 'spec_helper'

describe Polytexnic::Commands::Deployment do

  describe "default commands" do
    subject { Polytexnic::Commands::Deployment.default_commands }

    it { should match /poly build:all/ }
    it { should match /poly build:preview/ }
    it { should match /poly publish/ }
  end

  describe "commands helper" do
    let(:lines) { ['foo', ' #  bar', 'baz'] }
    subject { Polytexnic::Commands::Deployment.commands(lines) }

    it { should match /foo/ }
    it { should_not match /bar/ }
    it { should match /baz/ }
  end
end