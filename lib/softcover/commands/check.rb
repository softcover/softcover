# encoding: UTF-8

module Softcover
  module Commands
    module Check
      extend self
      extend Softcover::Utils

      def check_dependencies!
        puts "Checking Softcover dependencies..."
        simulate_work(1)
        missing_dependencies = []
        dependencies.each do |label, name|
          printf "%-30s", "Checking for #{name}..."
          simulate_work(0.15)
          if present?(label)
            puts "Found"
          else
            missing_dependencies << label
            puts "Missing"
          end
          simulate_work(0.1)
        end
        simulate_work(0.25)
        if missing_dependencies.empty?
          puts "All dependencies satisfied."
        else
          puts "Missing dependencies:"
          missing_dependencies.each do |dependency|
            puts "  • " + missing_dependency_message(dependency)
          end
        end
      end

      def dependencies
        [[:latex,       'LaTeX'],
         [:ghostscript, 'GhostScript'],
         [:convert,     'ImageMagick'],
         [:node,        'Node.js'],
         [:phantomjs,   'PhantomJS'],
         [:inkscape,    'Inkscape'],
         [:calibre,     'Calibre'],
         [:java,        'Java'],
         [:zip,         'zip'],
         [:epubcheck,   'EpubCheck'],
         [:python2,     'Python 2']
        ]
      end

      def dependency_labels
        dependencies.map(&:first)
      end

      def dependency_names
        dependencies.map { |e| e[1] }
      end

      def missing_dependency_message(label)
        case label
        when :latex
          message  = "LaTeX (https://latex-project.org/ftp.html)\n"
          message += "      ∟ Huge download—start it now!"
        when :ghostscript
          message  = "GhostScript (should come with LaTeX)\n"
        when :convert
          "ImageMagick (https://www.imagemagick.org/script/download.php)"
        when :node
          "NodeJS (https://nodejs.org/)"
        when :phantomjs
          message = "PhantomJS (https://phantomjs.org/download.html)\n"
          message += "      ∟ Put bin/phantomjs version 2 somewhere on your path,"
          message += " e.g., in /usr/local/bin"
        when :calibre
          url = 'https://calibre-ebook.com/'
          message  = "Calibre (#{url})\n"
          message += "      ∟ Enable Calibre command-line tools"
          message += " (https://manual.calibre-ebook.com/generated/en/cli-index.html)"
        when :java
          url = 'https://www.java.com/en/download/help/index_installing.xml'
          "Java (#{url})"
        when :zip
          "Install zip (e.g., apt-get install zip)"
        when :epubcheck
          url  = 'https://github.com/IDPF/epubcheck/releases/download/v4.2.2/epubcheck-4.2.2.zip'
          message  = "EpubCheck 4.2.2 (#{url})\n"
          message += "      ∟ Unzip and place epubcheck-4.2.2/ in a directory on your path"
        when :inkscape
          message  = "Inkscape (https://inkscape.org/)"
        when :python2
          message = "Configure your shell so that `python` runs Python 2"
        else
          raise "Unknown label #{label}"
        end
      end

      def present?(label)
        File.exist?(dependency_filename(label))
      end

      # Simulate working for given time.
      # `softcover check` is more satisfying if it looks like it's doing work.
      def simulate_work(time)
        return
        sleep time unless Softcover::test?
      end

    end
  end
end
