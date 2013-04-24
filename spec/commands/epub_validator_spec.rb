require 'spec_helper'

describe Polytexnic::Commands::EpubValidator do
  before(:all) { generate_book }
  after(:all)  { remove_book }

  it "should validate the EPUB" do
    validated = false
    Polytexnic::Book.any_instance.stub(:epubcheck) do
      validated = true
    end

    Polytexnic::Commands::EpubValidator.validate!

    expect(validated).to be_true
  end
end
