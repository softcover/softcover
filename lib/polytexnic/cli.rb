require "thor"

module Polytexnic
  class CLI < Thor
    include Polytexnic::Utils

    # ===============================================
    # Builder
    # ===============================================

    desc 'build, build:all', 'Build all formats'
    method_option :quiet, aliases: '-q',
                          desc: "Quiet output", type: :boolean
    method_option :silent, aliases: '-s',
                           desc: "Silent output", type: :boolean
    def build
      Polytexnic::Commands::Build.all_formats(options)
    end
    map "build:all" => "build"

    Polytexnic::FORMATS.each do |format|
      desc "build:#{format}", "Build #{format.upcase}"
      if format == 'pdf'
        method_option :debug, aliases: '-d',
                              desc: "Run raw xelatex for debugging purposes",
                              type: :boolean
      end
      method_option :quiet, aliases: '-q',
                            desc: "Quiet output", type: :boolean
      method_option :silent, aliases: '-s',
                             desc: "Silent output", type: :boolean
      define_method "build:#{format}" do
        Polytexnic::Commands::Build.for_format format, options
      end
    end

    # ===============================================
    # Preview
    # ===============================================
    desc "build:preview", "Build book preview in all formats"
    method_option :quiet, aliases: '-q',
                          desc: "Quiet output", type: :boolean
    method_option :silent, aliases: '-s',
                           desc: "Silent output", type: :boolean
    define_method "build:preview" do
      Polytexnic::Commands::Build.preview(options)
    end

    # ===============================================
    # Server
    # ===============================================

    desc 'server', 'Run local server'
    method_option :port, type: :numeric, default: 4000, aliases: '-p'
    def server
      if Polytexnic::BookManifest::valid_directory?
        Polytexnic::Commands::Server.run options[:port]
      else
        puts 'Not in a valid book directory.'
        exit 1
      end
    end

    # ===============================================
    # Auth
    # ===============================================

    desc "login", "Log into Softcover account"
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

    desc "logout", "Log out of Softcover account"
    def logout
      Polytexnic::Commands::Auth.logout
    end

    # ===============================================
    # Publisher
    # ===============================================

    desc "publish", "Publish your book on Softcover"
    def publish
      require 'polytexnic/commands/publisher'

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
    define_method "publish:screencasts" do |dir=
      Polytexnic::Book::DEFAULT_SCREENCASTS_DIR|

      puts "Publishing screencasts in #{dir}"
      Polytexnic::Commands::Publisher.
        publish_screencasts! options.merge(dir: dir)
    end

    # ===============================================
    # Generator
    # ===============================================

    desc "new <name>", "Generate new book directory structure."
    method_option :markdown,
                  :type => :boolean,
                  :default => false,
                  :aliases => "-m",
                  :desc => "Generate a Markdown book."
    method_option :simple,
                  :type => :boolean,
                  :default => false,
                  :aliases => "-s",
                  :desc => "Generate a simple book."
    def new(n)
      Polytexnic::Commands::Generator.generate_directory(n, options)
    end

    # ===============================================
    # Open
    # ===============================================

    desc "open", "Open book on Softcover website (OS X only)"
    def open
      Polytexnic::Commands::Opener.open!
    end

    # ===============================================
    # EPUB validate
    # ===============================================

    desc "epub:validate, epub:check", "Validate EPUB with epubcheck"
    define_method "epub:validate" do
      Polytexnic::Commands::EpubValidator.validate!
    end
    map "epub:check" => "epub:validate"

    # ===============================================
    # Config
    # ===============================================

    desc "config", "View local config"
    def config
      require "polytexnic/config"
      Polytexnic::Config.read
    end

    desc "config:add key=value", "Add to your local config vars"
    define_method "config:add" do |pair|
      require "polytexnic/config"
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
