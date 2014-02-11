module Softcover
  module Commands
    module Check
      extend self

      def check_dependencies!
        all_satisfied = true
        puts "Checking Softcover dependencies..."
        sleep 0.5
        dependencies.each do |label, name|
          printf "%-30s", "Checking for #{name}..."
          sleep 0.25
          if present?(label)
            puts "Found"
          else
            all_satisfied = false
            puts "Missing"
          end
        end
        if all_satisfied
          sleep 0.5
          puts "All dependencies satisfied."
        end
      end

      def dependencies
        [[:latex,       'LaTeX'],
         [:phantomjs,   'PhantomJS'],
         [:inkscape,    'Inkscape'],
         [:calibre,     'Calibre'],
         [:kindlegen,   'KindleGen'],
         [:java,        'Java'],
         [:epubcheck,   'EpubCheck'],
         [:ghostscript, 'GhostScript'],
        ]
      end

      def dependency_labels
        dependencies.map(&:first)
      end

      def dependency_names
        dependencies.map { |e| e[1] }
      end

      def present?(label)
        File.exist?(filename(label))
      end

      def filename(label)
        case label
        when :latex
          `which xelatex`.chomp
        when :phantomjs
          `which phantomjs`.chomp
        when :kindlegen
          `which kindlegen`.chomp
        when :java
          `which java`.chomp
        when :calibre
          `which ebook-convert`.chomp
        when :ghostscript
          `which gs`.chomp
        when :epubcheck
          File.join(Dir.home, 'epubcheck-3.0', 'epubcheck-3.0.jar')
        when :inkscape
          filename = `which inkscape`.chomp
          if filename.empty?
            filename = '/Applications/Inkscape.app/Contents/Resources/bin/' +
                       'inkscape'
          end
          filename
        else
          raise "Unknown label #{label}"
        end
      end

    end
  end
end
