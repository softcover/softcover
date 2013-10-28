require 'erb'
module Polytexnic
  module Commands
    module Generator
      include Polytexnic::Output
      extend self

      # Generates the default book file tree.
      def generate_file_tree(name, options = {})
        @name = name
        @markdown = options[:markdown]
        @simple   = options[:simple]

        thor = Thor::Shell::Basic.new

        puts "generating directory: #{name}"

        overwrite_all = false

        FileUtils.mkdir name unless File.exist?(name)
        Dir.chdir name

        # Create the directories.
        # There was some trouble with MathJax where it was trying to copy a
        # file before the directory had been created, so we now create all
        # the directories first.
        directories.each do |path|
          next if path =~ /\/simple_book/ && !@simple
          next if path =~ /\/book/ && @simple
          (cp_path = path.dup).slice! template_dir + "/"
          FileUtils.mkdir cp_path unless File.exist?(cp_path)
        end

        # Create the files.
        files.each do |path|
          next if path =~ /\/.$|\/..$/

          (cp_path = path.dup).slice! template_dir + "/"

          if path =~ /book\.tex/
            cp_path = "#{name}.tex"
          elsif path =~ /\.erb/
            cp_path = File.basename path.dup, '.erb'
          elsif path =~ /gitignore/
            cp_path = '.gitignore'
          end

          display_path = File.join name, cp_path

          if File.exist?(cp_path) && !overwrite_all
            res = thor.ask "#{display_path} already exists. " \
                           "Overwrite? (yes,no,all):"

            overwrite = case res
            when /y|yes/ then true
            when /n|no/  then false
            when /a|all/ then
              overwrite_all = true
              true
            end

            next unless overwrite
          end

          if path =~ /\.erb/
            erb = ERB.new(File.read(path)).result(binding)
            File.open(cp_path, 'w') { |f| f.write erb }
          else
            FileUtils.cp path, cp_path
          end
        end

        # Symlink the images directory.
        Dir.chdir "html"
        FileUtils.rm_f("images") if File.directory?("images")
        File.symlink("../images", "images")

        Dir.chdir "../.."
        puts "Done. Please update book.yml"
      end

      def template_dir
        File.expand_path File.join File.dirname(__FILE__), "../template"
      end

      # Returns true for a simple book (no frontmatter, etc.).
      def simple?
        @simple
      end

      # Returns a list of all the files and directories used to build the book.
      def all_files_and_directories
        f = files_directories_maybe_markdown
        simple? ? f.reject { |p| p =~ /\/book\.tex/ || p =~ /preface/ }
                : f.reject { |p| p =~ /simple/ }
      end

      # Returns the files and directories based on the input format.
      def files_directories_maybe_markdown
        fds = Dir.glob(File.join(template_dir, "**/*"), File::FNM_DOTMATCH)
        if markdown?
          # Skip the PolyTeX chapter files, which will be generated later.
          fds.reject { |e| e =~ /\/chapters\/.*/ }
        else
          # Skip the markdown directory.
          fds.reject { |e| e =~ /markdown/ }
        end
      end

      # Returns just the directories used for building the book.
      def directories
        all_files_and_directories.select { |path| File.directory?(path) }
      end

      # Returns just the files (not directories) used for building the book.
      def files
        all_files_and_directories.reject { |path| File.directory?(path) }
      end

      def markdown?
        @markdown
      end

      def verify!
        generated_files = Dir.glob("**/*", File::FNM_DOTMATCH).map do |f|
          File.basename(f)
        end

        Polytexnic::Commands::Generator.all_files_and_directories.each do |file|
          path = if file =~ /book\.tex/
                   "#{@name}.tex"
                 elsif file =~ /\.erb/
                   File.basename(file, '.erb')
                 elsif file =~ /gitignore/
                   '.gitignore'
                 else
                   File.basename(file)
                 end
          raise "missing #{file}" unless generated_files.include?(path)
        end
      end
    end
  end
end
