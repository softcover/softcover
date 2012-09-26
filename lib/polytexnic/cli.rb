require "thor"
require "thor/group"

module Polytexnic
	class CLI < Thor

		desc 'build', 'Build all formats.'
		def build
			Polytexnic::Commands::Build.all_formats
		end

		Polytexnic::FORMATS.each do |format|
			desc "build:#{format}", "Build #{format}"
			define_method "build:#{format}" do
				Polytexnic::Commands::Build.for_format format
			end
		end

		desc "login", "Log into polytexnic.com account"
		def login
			Polytexnic::Commands::Auth.login
		end

		desc "logout", "Log out of polytexnic.com account"
		def logout
			Polytexnic::Commands::Auth.logout
		end

		desc "publish", "Publish your book on polytexnic.com"
		def publish
			Polytexnic::Commands::Publisher.publish!
		end

		desc "new <name>", "Generate new book directory structure."
		def new(name)
			Polytexnic::Commands::Generator.generate_directory name
		end
	end
end
