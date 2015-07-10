require 'fileutils'

module Softcover
  module Builders
    class Html < Builder
      include Softcover::Utils

      def setup(options)
        Dir.mkdir "html" unless File.directory?("html")
        html_styles = path('html/stylesheets')
        unless File.directory?(html_styles)
          Dir.mkdir html_styles
        end
        template_dir = Softcover::Utils.template_dir(options)
        custom_css = path("#{template_dir}/html/stylesheets/custom.css")
        target = path("#{html_styles}/custom.css")
        FileUtils.cp(custom_css, target) unless File.exist?(target)
        clean!
      end

      def build(options = {})
        if Softcover::profiling?
          require 'ruby-prof'
          RubyProf.start
        end

        if manifest.markdown?
          unless options[:'find-overfull']
            remove_unneeded_polytex_files
          end
          manifest.chapters.each do |chapter|
            write_latex_files(chapter, options)
          end

          # Reset the manifest to use PolyTeX.
          self.manifest = Softcover::BookManifest.new(source: :polytex,
                                                      verify_paths: false,
                                                      origin: :markdown)
        end

        if manifest.polytex?
          basename = File.basename(manifest.filename, '.tex')
          @html  = converted_html(basename)
          @title = basename
          @mathjax = Softcover::Mathjax::config(chapter_number: false)
          @src     = Softcover::Mathjax::AMS_SVG
          erb_file = File.read(File.join(File.dirname(__FILE__),
                                         '..', 'server', 'views',
                                         'book.html.erb'))
          file_content = ERB.new(erb_file).result(binding)
          write_full_html_file(manifest.slug, file_content, options)
          write_chapter_html_files(Nokogiri::HTML(file_content), erb_file)
        end

        if Softcover::profiling?
          result = RubyProf.stop
          printer = RubyProf::GraphPrinter.new(result)
          printer.print(STDOUT, {})
        end
        write_master_latex_file(manifest)
        true
      end

      # Removes any PolyTeX files not corresponding to current MD chapters.
      def remove_unneeded_polytex_files
        files_to_keep = manifest.chapters.map do |chapter|
                          path("#{manifest.polytex_dir}/#{chapter.slug}.tex")
                        end
        all_files = Dir.glob(path("#{manifest.polytex_dir}/*.tex"))
        files_to_remove = all_files - files_to_keep
        FileUtils.rm(files_to_remove)
      end

      # Writes the LaTeX files for a given Markdown chapter.
      def write_latex_files(chapter, options = {})
        polytex_filename = path("#{manifest.polytex_dir}/#{chapter.slug}.tex")
        if chapter.source == :polytex
          FileUtils.cp path("chapters/#{chapter.full_name}"), polytex_filename
        else
          mkdir Softcover::Directories::TMP
          markdown = File.read(path("chapters/#{chapter.full_name}"))
          # Only write if the Markdown file hasn't changed since the last time
          # it was converted, as then the current PolyTeX file is up-to-date.
          # The call to File.exist?(filename) is just in case the PolyTeX file
          # corresponding to the Markdown file was removed by hand in the
          # interim.
          unless (File.exist?(chapter.cache_filename) &&
                  File.read(chapter.cache_filename) == digest(markdown) &&
                  File.exist?(polytex_filename) &&
                  !markdown.include?('\input'))
            File.write(polytex_filename, polytex(chapter, markdown))
          end
        end
      end

      # Returns the PolyTeX for the chapter.
      # As a side-effect, we cache a digest of the Markdown to prevent
      # unnecessary conversions.
      def polytex(chapter, markdown)
        File.write(chapter.cache_filename, digest(markdown))
        p = Polytexnic::Pipeline.new(markdown,
                                     source: :markdown,
                                     custom_commands: Softcover.custom_styles,
                                     language_labels: language_labels,
                                     article: Softcover::Utils.article?)
        p.polytex
      end

      # Returns the converted HTML.
      def converted_html(basename)
        polytex_filename = basename + '.tex'
        polytex = File.read(polytex_filename)
        # Replace the includes with the file contents, padding with a trailing
        # newline for safety.
        polytex.gsub!(/(^\s*\\include{(.*?)})/) do
          File.read($2 + '.tex') + "\n"
        end
        Polytexnic::Pipeline.new(polytex,
                                 custom_commands: Softcover.custom_styles,
                                 language_labels: language_labels,
                                 article: Softcover::Utils.article?).to_html
      end

      # Writes the full HTML file for the book.
      # The resulting file is a self-contained HTML document suitable
      # for viewing in isolation.
      def write_full_html_file(basename, file_content, options)
        html_filename = File.join('html', basename + '.html')
        File.open(html_filename, 'w') do |f|
          f.write(file_content)
        end
        polytexnic_css = File.join('html', 'stylesheets', 'softcover.css')
        source_css     = File.join(Softcover::Utils.template_dir(options),
                                   polytexnic_css)
        FileUtils.cp source_css, polytexnic_css
        write_pygments_file(:html, File.join('html', 'stylesheets'))
        built_files.push html_filename
      end

      # Writes the full HTML file for each chapter.
      # The resulting files are self-contained HTML documents suitable
      # for viewing in isolation.
      def write_chapter_html_files(html, erb_file)
        reference_cache = split_into_chapters(html)
        target_cache = build_target_cache(html)
        manifest.chapters.each_with_index do |chapter, i|
          update_cross_references(chapter, reference_cache, target_cache)
          write_fragment_file(chapter)
          write_complete_file(chapter, erb_file, i)
        end
      end

      # Splits the full XML document into chapters.
      def split_into_chapters(xml)
        chapter_number = 0
        current_chapter = manifest.chapters.first
        reference_cache = {}
        if Softcover::Utils.article?
          # Include all the material before the first section.
          xml.css('#book').children.each do |node|
            next  if node['id'] == 'title_page'
            break if node['class'] == 'section'
            current_chapter.nodes.push node
            node.remove
          end
        end
        xml.css('#book>div').each do |node|
          # Include the title page info.
          if node['id'] == 'title_page'
            current_chapter.nodes.unshift node
          else
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
        end
        reference_cache
      end

      # Builds a cache of targets for cross-references.
      def build_target_cache(xml)
        {}.tap do |target_cache|
          xml.xpath("//*[@id]").each do |target|
            target_cache[target['id']] = target
          end
        end
      end

      # Updates the book's cross-references.
      def update_cross_references(chapter, ref_map, target_cache)
        chapter.nodes.each do |node|
          node.css('a.hyperref').each do |ref_node|
            ref_id = ref_node['href'][1..-1]  # i.e., 'cha-foo_bar'
            target = target_cache[ref_id]
            unless target.nil?
              id = target['id']
              ref_chapter = if target['data-tralics-id'].nil?
                              # This branch is true for chapter-star.
                              chapter
                            else
                              ref_map[target['data-tralics-id']]
                            end
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
        # Make references absolute.
        chapter.nodes.each do |node|
          node.css('a.hyperref').each do |ref_node|
            ref_node['href'] = ref_node['href'].sub('_fragment', '')
          end
        end
        File.open(html_filename, 'w') do |f|
          @html = chapter.nodes.map(&:to_xhtml).join("\n")
          @mathjax = Softcover::Mathjax::config(chapter_number: n)
          @src     = Softcover::Mathjax::AMS_SVG
          file_content = ERB.new(erb_file).result(binding)
          f.write(file_content)
        end
        built_files.push html_filename
      end

      def clean!
        # It's safe to remove HTML files in the html/ directory,
        # as they are regenerated every time the book gets built.
        # This also arranges to clear out unused HTML files, as happens when,
        # e.g., the name of a LaTeX chapter file changes.
        FileUtils.rm(Dir.glob(path('html/*.html')))
      end
    end
  end
end
