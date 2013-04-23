require 'spec_helper'

describe Polytexnic::Commands::EpubValidator do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  it "should validate the EPUB" do
    validated = false
    Polytexnic::Book.any_instance.stub(:validate) do
      validated = true
    end

    Polytexnic::Commands::EpubValidator.validate!

    validated.should be_true
  end
end
