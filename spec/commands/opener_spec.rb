require 'spec_helper'

describe Softcover::Commands::Opener do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  it 'opens in browser' do
    opened = false
    Softcover::Book.any_instance.stub(:open_in_browser) do
      opened = true
    end

    Softcover::Commands::Opener.open!

    expect(opened).to be_true
  end
end
