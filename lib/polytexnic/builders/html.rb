require 'fileutils'

module Polytexnic
  module Builders
    class Html < Builder

      def setup
        Dir.mkdir "html" unless File.directory?("html")
        unless File.directory?(File.join("html", "stylesheets"))
          Dir.mkdir File.join("html", "stylesheets")
        end
      end

      def build(options = {})
        if Polytexnic::profiling?
          require 'ruby-prof'
          RubyProf.start
        end

        if manifest.markdown?
          manifest.chapters.each do |chapter|
            path = File.join('markdown', chapter.slug)
            md = Polytexnic::Core::Pipeline.new(File.read(path), format: :md)
            basename = File.basename path, ".*"
            File.write(File.join("chapters", "#{basename}.tex"), md.polytex)
            manifest = Polytexnic::BookManifest.new(format: :polytex,
                                                    verify_paths: true)
            # Recursively call `build` using the new PolyTeX manifest.
            build
          end
        else
          basename = File.basename(manifest.filename, '.tex')
          polytex_filename = basename + '.tex'
          polytex = File.read(polytex_filename)
          polytex.gsub!(/(^\s*\\include{(.*?)})/) do
            File.read($2 + '.tex')
          end
          html_body = Polytexnic::Core::Pipeline.new(polytex).to_html
          html_filename = File.join('html', basename + '.html')
          @html = html_body
          @title = basename
          erb_file = File.read(File.join(File.dirname(__FILE__),
                                         '../server/views/book.html.erb'))
          file_content = ERB.new(erb_file).result(binding)

          File.open(html_filename, 'w') do |f|
            f.write(file_content)
          end
          polytexnic_css = File.join('html', 'stylesheets', 'polytexnic.css')
          source_css     = File.join(File.dirname(__FILE__),
                                     "../template/#{polytexnic_css}")
          FileUtils.cp source_css, polytexnic_css
          write_pygments_file(:html, File.join('html', 'stylesheets'))
          @built_files.push html_filename

          xml = Nokogiri::HTML(file_content)

          create_html_fragments

          # split nodes to chapters
          ref_map = {}
          chapter_number = 0
          current_chapter = manifest.chapters.first

          xml.css('#book>div').each do |node|
            if node.attributes['class'].to_s == 'chapter'
              current_chapter = manifest.chapters[chapter_number]
              node['data-chapter'] = current_chapter.slug
              chapter_number += 1
            end

            ref_map[node['data-tralics-id']] = current_chapter
            node.xpath('.//*[@data-tralics-id]').each do |labeled_node|
              ref_map[labeled_node['data-tralics-id']] = current_chapter
            end

            current_chapter.nodes.push node
          end

          target_cache = {}
          xml.xpath("//*[@id]").each do |target|
            target_cache[target['id']] = target
          end

          # write chapter nodes to fragment file
          manifest.chapters.each_with_index do |chapter, i|
            # Update cross-chapter refs.
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

            html_filename = File.join('html', chapter.slug + '_fragment.html')
            File.open(html_filename, 'w') do |f|
              chapter.nodes.each do |node|
                f.write(node.to_xhtml)
              end
            end

            @built_files.push html_filename

            # Write complete documents, including MathJax.
            html_filename = File.join('html', chapter.slug + '.html')
            File.open(html_filename, 'w') do |f|
              @html = chapter.nodes.map(&:to_xhtml).join("\n")
              @mathjax = Polytexnic::Mathjax::config(chapter_number: i+1)
              @src     = Polytexnic::Mathjax::AMS_SVG
              file_content = ERB.new(erb_file).result(binding)
              f.write(file_content)
            end
            @built_files.push html_filename
          end
        end

        if Polytexnic::profiling?
          result = RubyProf.stop
          printer = RubyProf::GraphPrinter.new(result)
          printer.print(STDOUT, {})
        end

        true
      end

      def create_html_fragments
        current_chapter = manifest.chapters.first

        manifest.chapters.each do |chapter|
          filename = File.join('html', chapter.slug + '_fragment.html')
          File.unlink(filename) if File.exists?(filename)
        end
      end

      def clean!
        FileUtils.rm_rf "html"
      end
    end
  end
end
