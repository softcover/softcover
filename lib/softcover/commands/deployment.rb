module Softcover
  module Commands
    module Deployment
      include Softcover::Utils
      extend self

      # Deploy a book by building and publishing it.
      # The deploy steps can be customized using `.poly-publish`
      # in the book project's home directory.
      def deploy!
        if File.exist?('.softcover-deploy') && !custom_commands.empty?
          execute custom_commands
        else
          execute default_commands
        end
      end

      # Returns the default commands.
      def default_commands
        commands(['softcover build:all', 'softcover build:preview',
                  'softcover publish'])
      end

      # Returns custom commands (if any).
      def custom_commands
        commands(File.readlines(deploy_config).map(&:strip))
      end

      # Returns the filename for configuring `softcover deploy`.
      def deploy_config
        '.softcover-deploy'
      end

      # Returns the commands from the given lines.
      # We skip comments and blank lines.
      def commands(lines)
        skip = /(^\s*#|^\s*$)/
        lines.reject { |line| line =~ skip }.join("\n")
      end
    end
  end
end
