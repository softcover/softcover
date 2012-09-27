require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'

require 'polytexnic'

RSpec.configure do |config|
	config.before do
		Polytexnic::set_test_mode!
		Polytexnic::Config.remove
	end
end

TEST_API_KEY = 'asdfasdfasdfasdfasdf'

def stub_valid_login(email, pass, api_key=TEST_API_KEY)
	stub_request(:post, "#{Polytexnic::Config::DEFAULTS[:host]}/login").
    with(:body => {"email"=>email, "password"=>pass},
    	:headers => {'Accept'=>'application/json', 
    		'Accept-Encoding'=>'gzip, deflate', 
    		'Content-Length'=>/.+/, 
    		'Content-Type'=>'application/x-www-form-urlencoded', 
    		'User-Agent'=>'Ruby'} ).
    to_return(:status => 200, :body => {api_key: api_key})
end

def stub_invalid_login(email, pass)
	stub_request(:post, "#{Polytexnic::Config::DEFAULTS[:host]}/login").
    with(:body => {"email"=>email, "password"=>pass}, 
    	:headers => {'Accept'=>'application/json', 
    		'Accept-Encoding'=>'gzip, deflate', 
    		'Content-Length'=>/.+/, 
    		'Content-Type'=>'application/x-www-form-urlencoded', 
    		'User-Agent'=>'Ruby'} ).
    to_return(:status => 422, body: '')
end
