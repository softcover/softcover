module Softcover
  module Commands
    module Check
      extend self

      def check_dependencies!
        dependencies = [[:latex, 'LaTeX'],
                        [:calibre, 'Calibre']]

        dependencies.each do |label, name|
          printf "%-30s", "Checking for #{name}..."
          if present?(label)
            puts "Found."
          else
            puts "Not found."
          end
        end
      end

      def present?(program)
        case
        when :latex
          File.exist?(`which xelatex`.chomp)
        when :calibre
          File.exist?(`which ebook-convert`.chomp)
        end
      end

    end
  end
end
