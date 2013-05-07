require 'spec_helper'

describe Polytexnic::Commands::Server do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  before { chdir_to_book }

  it '#listen_for_changes' do
    subject.should_receive(:fork) do |&block|
      block.call
    end
    Listen.should_receive(:to) do |&block|
      block.call
    end
    expect { silence { subject.listen_for_changes } }.to raise_error SignalException
  end

  it '#run' do
    subject.should_receive(:fork)
    Polytexnic::App.should_receive :run!

    port = 5000
    silence { subject.run port }

    expect(Polytexnic::App.port).to eq port
  end
end
