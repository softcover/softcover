require "thor"
require "thor/group"

module Polytexnic
  class CLI < Thor
    include Thor::Actions
    include Polytexnic::Utils

    # ===============================================
    # Builder
    # ===============================================

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

    # ===============================================
    # Auth
    # ===============================================

    desc "login", "Log into polytexnic.com account"
    def login
      puts "Logging in."

      logged_in = false
      while not logged_in do
        email = ask "Email:"
        password = ask_without_echo "Password (won't be shown):"
        unless logged_in = Polytexnic::Commands::Auth.login(email, password)
          puts "Invalid login, please try again."
        end
      end
      puts "Welcome back, #{email}!"
    end

    desc "logout", "Log out of polytexnic.com account"
    def logout
      Polytexnic::Commands::Auth.logout
    end

    # ===============================================
    # Publisher
    # ===============================================

    desc "publish", "Publish your book on polytexnic.com"
    def publish
      invoke :login unless logged_in? 

      puts "Publishing..."
      Polytexnic::Commands::Publisher.publish!
    end

    desc "publish:screencasts", "Publish screencasts"
    method_option :daemon, aliases: '-d', force: false, 
      desc: "Run as daemon", type: :boolean
    method_option :watch, aliases: '-w', type: :boolean, 
      force: false, desc: "Watch a directory to auto upload."

    # TODO: make screencasts dir .book configurable
    define_method "publish:screencasts" do |dir="./screencasts"|

      puts "Publishing screencasts in #{dir}"
      Polytexnic::Commands::Publisher.publish_screencasts! dir, options
    end

    # ===============================================
    # Generator
    # ===============================================

    desc "new <name>", "Generate new book directory structure."
    def new(name)
      Polytexnic::Commands::Generator.generate_directory name
    end

    # ===============================================
    # Config
    # ===============================================

    desc "config", "View local config"
    def config
      Polytexnic::Config.read
    end

    desc "config:add key=value", "Add to your local config vars"
    define_method "config:add" do |pair|
      key, value = pair.split "="
      Polytexnic::Config[key] = value

      puts 'Config var added:'
      config
    end

    protected
      def ask_without_echo(*args)
        system "stty -echo"
        ret = ask *args
        system "stty echo"
        puts
        ret
      end
  end
end
