module Softcover
  module Commands
    module Check
      extend self

      def check_dependencies!
        dependencies = [[:latex, 'LaTeX']]

        dependencies.each do |label, name|
          print "Checking for #{name}... "
          if present?(label)
            puts "Found."
          else
            puts "Not found."
          end
        end
      end

      def present?(program)
        if program == :latex
          File.exist?(`which xelatex`.chomp)
        end
      end

    end
  end
end
