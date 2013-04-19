require 'spec_helper'

describe Polytexnic::Commands::Opener do
  before { chdir_to_book }

  it 'opens in browser' do
    opened = false
    Polytexnic::Book.any_instance.stub(:open_in_browser) do
      opened = true
    end

    Polytexnic::Commands::Opener.open!

    opened.should be_true
  end
end
