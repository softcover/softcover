require 'spec_helper'

describe Polytexnic::Builder do
  before(:all) { generate_book }
  after(:all)  { remove_book }
  
  it "should not raise an error" do
    expect(subject).not_to be_nil
  end
end