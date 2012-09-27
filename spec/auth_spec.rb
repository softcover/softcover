require 'spec_helper'

describe Polytexnic::Commands::Auth do
  context 'valid login' do
    before do
      email = 'valid@lemurheavy.com'
      pass = 'asdf'

      stub_valid_login email, pass, TEST_API_KEY

      Polytexnic::Commands::Auth.login email, pass
    end

    it 'should set the api key' do
      Polytexnic::Config['api_key'].should eq TEST_API_KEY
    end
  end

  context 'invalid login' do
    before do
      email = 'invalid@lemurheavy.com'
      pass = 'asdf'

      stub_invalid_login email, pass

      Polytexnic::Commands::Auth.login email, pass
    end

    it 'should not set the api key' do
      Polytexnic::Config['api_key'].should be_nil
    end
  end

  context "logging out" do
    before do
      Polytexnic::Config['api_key'] = 'asdfasdf'
      Polytexnic::Commands::Auth.logout
    end

    it "should unset the api_key" do
      Polytexnic::Config['api_key'].should be_nil
    end
  end
end