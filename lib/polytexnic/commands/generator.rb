require 'erb'
module Polytexnic
  module Commands
    module Generator
      extend self

      def generate_directory(name)
        @name = name

        thor = Thor::Shell::Basic.new

        puts "generating directory: #{name}"

        overwrite_all = false

        FileUtils.mkdir name unless File.exist?(name)
        Dir.chdir name

        # Create directories.
        # There was some trouble with MathJax where it was trying to copy a
        # file before the directory had been created.
        template_files.select { |path| File.directory?(path) }.each do |path|
          (cp_path = path.dup).slice! template_dir + "/"
          FileUtils.mkdir cp_path unless File.exist?(cp_path)
        end

        template_files.reject { |path| File.directory?(path) }.each do |path|
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
            when /n|no/ then false
            when /a|all/ then
              overwrite_all = true
              true
            end

            next unless overwrite
          else
            puts display_path
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

      def template_files
        Dir.glob(File.join(template_dir, "**/*"), File::FNM_DOTMATCH)
      end

      def verify!
        generated_files = Dir.glob("**/*", File::FNM_DOTMATCH).map do |f|
          File.basename(f)
        end

        Polytexnic::Commands::Generator.template_files.each do |file|
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
