
module Softcover
  module Commands
    module Exercises
      extend self

      def add_to_chapters!
        require 'securerandom'

        Dir["chapters/*.tex"].each do |path|

        	str = ""

        	in_exercise = false
        	n = 0
        	line_number = 0

        	lines = []
        	File.read(path).each_line { |line| lines.push line }

        	lines.each do |line|
        		str += line

        		case line
        		when %r{\\subsubsection{Exercises}}
        			in_exercise = true
        		when %r{\\end{enumerate}}
        			in_exercise = false
        		when %r{\\item}
        			if in_exercise && !(lines[line_number + 1] =~ /^%= <span/)
        				str += "%= <span class='exercise' id='ex-#{SecureRandom.hex(3)}'></span>\n"
        				n += 1
        			end
        		end

        		line_number += 1
        	end

        	File.open(path, "w") { |f| f.write str }

            exercises = n == 1 ? "exercise" : "exercises"
        	puts "#{path}: wrote #{n} #{exercises}"
        end
      end

    end
  end
end
