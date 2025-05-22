module Softcover
  class BaseConfig

    DEFAULTS = {
      host: 'https://www.softcover.io'
    }

    PATH = '.'

    class << self
      def [](key)
        store.transaction do
          store[key]
        end || DEFAULTS[key.to_sym]
      end

      def []=(key, value)
        store.transaction do
          store[key] = value
        end
      end

      def read
        puts `cat #{file_path}`
      end

      def remove
        File.delete(file_path) if exists?
      end

      def exists?
        File.exist?(file_path)
      end

      protected
        def store
          require 'yaml/store'
          @store ||= begin
             YAML::Store.new(file_path)
          end
        end

        def file_path
          File.expand_path(path).tap do |full_path|
            full_path.gsub!(/$/,"-test") if Softcover::test?
          end
        end
    end
  end

  class BookConfig < BaseConfig
    def self.path
      ".softcover-book"
    end
  end

  class Config < BaseConfig
    def self.path
      File.exist?(".softcover") ? ".softcover" : "~/.softcover"
    end
  end
end