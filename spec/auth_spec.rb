require 'spec_helper'

describe Softcover::Commands::Auth do
  context 'valid login' do
    before do
      email = 'valid@lemurheavy.com'
      pass = 'asdf'

      stub_valid_login email, pass, TEST_API_KEY

      Softcover::Commands::Auth.login email, pass
    end

    it 'should set the api key' do
      expect(Softcover::Config['api_key']).to eq TEST_API_KEY
    end
  end

  context 'invalid login' do
    before do
      email = 'invalid@lemurheavy.com'
      pass = 'asdf'

      stub_invalid_login email, pass

      Softcover::Commands::Auth.login email, pass
    end

    it 'should not set the api key' do
      expect(Softcover::Config['api_key']).to be_nil
    end
  end

  context "logging out" do
    before do
      Softcover::Config['api_key'] = 'asdfasdf'
      Softcover::Commands::Auth.logout
    end

    it "should unset the api_key" do
      expect(Softcover::Config['api_key']).to be_nil
    end
  end
end