module Polytexnic
  module Builders
    class Pdf < Builder

      def build!
        # Process the raw PolyTeX into LaTeX (with syntax highlighting, etc.).
        # TODO: add processing step (from polytexnic-core)
        cmd = "pdflatex #{@manifest.filename}"
        # Run the command twice to guarantee up-to-date cross-references.
        system("#{cmd} && #{cmd}")
      end

    end
  end
end