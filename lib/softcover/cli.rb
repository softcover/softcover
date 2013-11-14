require "thor"

module Softcover
  class CLI < Thor
    include Softcover::Utils

    map "-v" => :version

    desc "version", "Returns the version number"
    method_option :version, aliases: '-v',
                            desc: "Print version number", type: :boolean
    def version
      require 'softcover/version'
      puts "Softcover #{Softcover::VERSION}"
      exit 0
    end

    # ===============================================
    # Builder
    # ===============================================

    desc 'build, build:all', 'Build all formats'
    method_option :quiet, aliases: '-q',
                          desc: "Quiet output", type: :boolean
    method_option :silent, aliases: '-s',
                           desc: "Silent output", type: :boolean
    def build
      Softcover::Commands::Build.all_formats(options)
    end
    map "build:all" => "build"

    Softcover::FORMATS.each do |format|
      desc "build:#{format}", "Build #{format.upcase}"
      if format == 'pdf'
        method_option :debug, aliases: '-d',
                              desc: "Run raw xelatex for debugging purposes",
                              type: :boolean
        method_option :once, aliases: '-o',
                             desc: "Run PDF generator once (no xref update)",
                             type: :boolean
        method_option :'find-overfull', aliases: '-f',
                                        desc: "Find overfull hboxes",
                                        type: :boolean
      end
      method_option :quiet, aliases: '-q',
                            desc: "Quiet output", type: :boolean
      method_option :silent, aliases: '-s',
                             desc: "Silent output", type: :boolean
      define_method "build:#{format}" do
        Softcover::Commands::Build.for_format format, options
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
      Softcover::Commands::Build.preview(options)
    end

    # ===============================================
    # Server
    # ===============================================

    desc 'server', 'Run local server'
    method_option :port, type: :numeric, default: 4000, aliases: '-p'
    def server
      if Softcover::BookManifest::valid_directory?
        Softcover::Commands::Server.run options[:port]
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
        unless logged_in = Softcover::Commands::Auth.login(email, password)
          puts "Invalid login, please try again."
        end
      end
      puts "Welcome back, #{email}!"
    end

    desc "logout", "Log out of Softcover account"
    def logout
      Softcover::Commands::Auth.logout
    end

    # ===============================================
    # Publisher
    # ===============================================

    desc "publish", "Publish your book on Softcover"
    method_option :quiet, aliases: '-q',
                          desc: "Quiet output", type: :boolean
    method_option :silent, aliases: '-s',
                           desc: "Silent output", type: :boolean
    def publish
      require 'softcover/commands/publisher'

      invoke :login unless logged_in?

      puts "Publishing..." unless options[:silent]
      Softcover::Commands::Publisher.publish!(options)
    end

    desc "publish:screencasts", "Publish screencasts"
    method_option :daemon, aliases: '-d', force: false,
      desc: "Run as daemon", type: :boolean
    method_option :watch, aliases: '-w', type: :boolean,
      force: false, desc: "Watch a directory to auto upload."

    # TODO: make screencasts dir .book configurable
    define_method "publish:screencasts" do |dir=
      Softcover::Book::DEFAULT_SCREENCASTS_DIR|

      puts "Publishing screencasts in #{dir}"
      Softcover::Commands::Publisher.
        publish_screencasts! options.merge(dir: dir)
    end

    desc "unpublish", "Removes book from Softcover"
    def unpublish
      require 'softcover/commands/publisher'

      invoke :login unless logged_in?

      slug = Softcover::BookManifest.new.slug
      if ask("Type '#{slug}' to unpublish:") == slug
        puts "Unpublishing..." unless options[:silent]
        Softcover::Commands::Publisher.unpublish!
      else
        puts "Canceled."
      end
    end

    # ===============================================
    # Deployment
    # ===============================================
    desc "deploy", "Build & publish book (configure using .softcover-deploy)"
    def deploy
      Softcover::Commands::Deployment.deploy!
    end

    # ===============================================
    # Generator
    # ===============================================

    desc "new <name>", "Generate new book directory structure."
    method_option :polytex,
                  :type => :boolean,
                  :default => false,
                  :aliases => "-p",
                  :desc => "Generate a PolyTeX book."
    method_option :simple,
                  :type => :boolean,
                  :default => false,
                  :aliases => "-s",
                  :desc => "Generate a simple book."
    def new(n)
      Softcover::Commands::Generator.generate_file_tree(n, options)
    end

    # ===============================================
    # Open
    # ===============================================

    desc "open", "Open book on Softcover website (OS X)"
    def open
      Softcover::Commands::Opener.open!
    end

    # ===============================================
    # EPUB validate
    # ===============================================

    desc "epub:validate, epub:check", "Validate EPUB with epubcheck"
    define_method "epub:validate" do
      Softcover::Commands::EpubValidator.validate!
    end
    map "epub:check" => "epub:validate"

    # ===============================================
    # Config
    # ===============================================

    desc "config", "View local config"
    def config
      require "softcover/config"
      Softcover::Config.read
    end

    desc "config:add key=value", "Add to your local config vars"
    define_method "config:add" do |pair|
      require "softcover/config"
      key, value = pair.split "="
      Softcover::Config[key] = value

      puts 'Config var added:'
      config
    end

    desc "config:remove key", "Remove the key from your local config vars"
    define_method "config:remove" do |key|
      require "softcover/config"
      Softcover::Config[key] = nil

      puts 'Config var removed.'
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
