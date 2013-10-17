require 'fileutils'

module Polytexnic
  module Builders
    class Html < Builder

      def setup
        Dir.mkdir "html" unless File.directory?("html")
        unless File.directory?(path('html/stylesheets'))
          Dir.mkdir path('html/stylesheets')
        end
        # It's safe to remove HTML files in the html/ directory,
        # as they are always generated. This also arranges to clear
        # out unused HTML files, as happens when, e.g., the name of a
        # LaTeX chapter file changes.
        FileUtils.rm(Dir.glob(path('html/*.html')))
      end

      def build(options = {})
        if Polytexnic::profiling?
          require 'ruby-prof'
          RubyProf.start
        end

        if manifest.markdown?
          FileUtils.rm(Dir.glob(path('chapters/*.tex')))
          manifest.chapters.each do |chapter|
            write_latex_files(chapter)
          end
          rewrite_master_latex_file
          # Reset the manifest to use PolyTeX.
          @manifest = Polytexnic::BookManifest.new(source: :polytex,
                                                   verify_paths: true)
        end

        if manifest.polytex?
          basename = File.basename(manifest.filename, '.tex')
          @html  = converted_html(basename)
          @title = basename
          erb_file = File.read(File.join(File.dirname(__FILE__),
                                         '../server/views/book.html.erb'))
          file_content = ERB.new(erb_file).result(binding)
          write_full_html_file(basename, file_content)
          write_chapter_html_files(Nokogiri::HTML(file_content), erb_file)
        end

        if Polytexnic::profiling?
          result = RubyProf.stop
          printer = RubyProf::GraphPrinter.new(result)
          printer.print(STDOUT, {})
        end

        true
      end

      # Writes the LaTeX files for a given Markdown chapter.
      def write_latex_files(chapter)
        path = File.join('markdown', chapter.slug + '.md')
        md = Polytexnic::Core::Pipeline.new(File.read(path), source: :md)
        File.write(File.join("chapters", "#{chapter.slug}.tex"), md.polytex)
      end

      # Rewrites the master LaTeX file <name>.tex to use chapters from Book.txt.
      def rewrite_master_latex_file
        master_filename = Dir['*.tex'].reject { |f| f =~ /\.tmp/}.first
        lines = File.readlines('markdown/Book.txt')
        tex_file = []
        lines.each do |line|
          if line =~ /(.*)\.md\s*$/
            tex_file << "\\include{chapters/#{$1}}"
          elsif line =~ /(.*):\s*$/  # frontmatter or mainmatter
            tex_file << "\\#{$1}"
          elsif line.strip == 'cover'
            tex_file << '\\includepdf{images/cover.pdf}'
          else # raw command, like 'maketitle' or 'tableofcontents'
            tex_file << "\\#{line.strip}"
          end
        end
        tex_file << '\end{document}'
        content = File.read(master_filename)
        content.gsub!(/(\\begin{document}\n)(.*)/m) do
          $1 + tex_file.join("\n") + "\n"
        end
        File.write(master_filename, content)
      end

      # Returns the converted HTML.
      def converted_html(basename)
        polytex_filename = basename + '.tex'
        polytex = File.read(polytex_filename)
        polytex.gsub!(/(^\s*\\include{(.*?)})/) do
          File.read($2 + '.tex')
        end
        Polytexnic::Core::Pipeline.new(polytex).to_html
      end

      def write_full_html_file(basename, file_content)
        html_filename = File.join('html', basename + '.html')
        File.open(html_filename, 'w') do |f|
          f.write(file_content)
        end
        polytexnic_css = File.join('html', 'stylesheets', 'polytexnic.css')
        source_css     = File.join(File.dirname(__FILE__),
                                   "../template/#{polytexnic_css}")
        FileUtils.cp source_css, polytexnic_css
        write_pygments_file(:html, File.join('html', 'stylesheets'))
        built_files.push html_filename
      end

      def write_chapter_html_files(html, erb_file)
        reference_cache = split_into_chapters(html)
        target_cache = build_target_cache(html)
        manifest.chapters.each_with_index do |chapter, i|
          update_cross_references(chapter, reference_cache, target_cache)
          write_fragment_file(chapter)
          write_complete_file(chapter, erb_file, i)
        end
      end

      # Split the full XML document into chapters.
      def split_into_chapters(xml)
        chapter_number = 0
        current_chapter = manifest.chapters.first
        reference_cache = {}
        xml.css('#book>div').each do |node|
          klass = node.attributes['class'].to_s
          id = node.attributes['id'].to_s
          if klass == 'chapter' || id == 'frontmatter'
            current_chapter = manifest.chapters[chapter_number]
            node['data-chapter'] = current_chapter.slug
            chapter_number += 1
          end

          reference_cache[node['data-tralics-id']] = current_chapter
          node.xpath('.//*[@data-tralics-id]').each do |labeled_node|
            reference_cache[labeled_node['data-tralics-id']] = current_chapter
          end

          current_chapter.nodes.push node
        end
        reference_cache
      end

      def write_frontmatter_file(xml, id)
        if element = xml.at_css("div##{id}")
          File.write("html/#{id}_fragment.html", element.to_xhtml)
          element.remove
        end
      end

      # Builds a cache of targets for cross-references.
      def build_target_cache(xml)
        {}.tap do |target_cache|
          xml.xpath("//*[@id]").each do |target|
            target_cache[target['id']] = target
          end
        end
      end

      def update_cross_references(chapter, ref_map, target_cache)
        chapter.nodes.each do |node|
          node.css('a.hyperref').each do |ref_node|
            ref_id = ref_node['href'][1..-1]  # i.e., 'cha-foo_bar'
            target = target_cache[ref_id]
            unless target.nil?
              id = target['id']
              ref_chapter = ref_map[target['data-tralics-id']]
              ref_node['href'] = "#{ref_chapter.fragment_name}##{id}"
            end
          end
        end
      end

      # Writes the chapter fragment HTML (omitting, e.g., <html> tags, etc.)
      def write_fragment_file(chapter)
        html_filename = File.join('html', "#{chapter.slug}_fragment.html")
        File.open(html_filename, 'w') do |f|
          chapter.nodes.each do |node|
            f.write(node.to_xhtml)
          end
        end
        built_files.push html_filename
      end

      # Writes the chapter as a complete, self-contained HTML document.
      def write_complete_file(chapter, erb_file, n)
        html_filename = File.join('html', chapter.slug + '.html')
        File.open(html_filename, 'w') do |f|
          @html = chapter.nodes.map(&:to_xhtml).join("\n")
          @mathjax = Polytexnic::Mathjax::config(chapter_number: n)
          @src     = Polytexnic::Mathjax::AMS_SVG
          file_content = ERB.new(erb_file).result(binding)
          f.write(file_content)
        end
        built_files.push html_filename
      end

      def clean!
        FileUtils.rm_rf "html"
      end
    end
  end
end
