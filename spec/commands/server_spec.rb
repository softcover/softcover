require 'spec_helper'

describe Softcover::Commands::Server do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  before { chdir_to_book }

  it '#listen_for_changes' do
    expect { subject.listen_for_changes }.to_not raise_error(Exception)
  end

  it '#run' do
    Softcover::App.should_receive :run!

    port = 5000
    subject.run port

    expect(Softcover::App.port).to eq port
  end
end
