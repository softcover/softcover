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
         [:kindlegen,   'KindleGen'],
         [:java,        'Java'],
         [:zip,         'zip'],
         [:epubcheck,   'EpubCheck'],
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
          message  = "LaTeX (http://latex-project.org/ftp.html)\n"
          message += "      ∟ Huge download—start it now!"
        when :ghostscript
          message  = "GhostScript (should come with LaTeX)\n"
        when :convert
          "ImageMagick (https://www.imagemagick.org/script/download.php)"
        when :node
          "NodeJS (http://nodejs.org/)"
        when :phantomjs
          message = "PhantomJS (http://phantomjs.org/)\n"
          message += "      ∟ Put bin/phantomjs version 2 somewhere on your path,"
          message += " e.g., in /usr/local/bin"
        when :kindlegen
          url = 'http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211'
          message = "KindleGen (#{url})\n"
          message += "      ∟ Put the kindlegen executable on your path,"
          message += " e.g., in /usr/local/bin"
        when :calibre
          url = 'http://calibre-ebook.com/'
          message  = "Calibre (#{url})\n"
          message += "      ∟ Enable Calibre command-line tools"
          message += " (http://manual.calibre-ebook.com/generated/en/cli-index.html)"
        when :java
          url = 'http://www.java.com/en/download/help/index_installing.xml'
          "Java (#{url})"
        when :zip
          "Install zip (e.g., apt-get install zip)"
        when :epubcheck
          url  = 'https://github.com/IDPF/epubcheck/releases/'
          url += 'download/v4.0.1/epubcheck-4.0.1.zip'
          message  = "EpubCheck 4.0.1 (#{url})\n"
          message += "      ∟ Unzip and place epubcheck-4.0.1/ in a directory on your path"
        when :inkscape
          message  = "Inkscape (http://inkscape.org/)"
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
        sleep time unless Softcover::test?
      end

    end
  end
end
