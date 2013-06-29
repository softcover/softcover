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

      def build
        if @manifest.md?
          require 'maruku'
          @manifest.chapters.each do |chapter|
            path = chapter.slug

            md = Maruku.new File.read(path)

            basename = File.basename path, ".*"

            fragment_path = "html/#{basename}_fragment.html"
            f = File.open fragment_path, "w"
            f.write md.to_html
            f.close

            doc_path = "html/#{basename}.html"
            f = File.open doc_path, "w"
            f.write md.to_html_document
            f.close

            @built_files.push fragment_path, doc_path
          end
        else
          basename = File.basename(@manifest.filename, '.tex')
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

          # create HTML fragments
          current_chapter = @manifest.chapters.first

          @manifest.chapters.each do |chapter|
            filename = File.join('html', chapter.slug + '_fragment.html')
            File.unlink(filename) if File.exists?(filename)
          end

          # split nodes to chapters
          ref_map = {}
          chapter_number = 0
          current_chapter = @manifest.chapters.first

          xml.css('#book>div').each do |node|
            if node.attributes['class'].to_s == 'chapter'
              current_chapter = @manifest.chapters[chapter_number]
              node['data-chapter'] = current_chapter.slug
              chapter_number += 1
            end

            ref_map[node['data-tralics-id']] = current_chapter
            node.xpath('.//*[@data-tralics-id]').each do |labeled_node|
              ref_map[labeled_node['data-tralics-id']] = current_chapter
            end

            current_chapter.nodes.push node
          end

          # write chapter nodes to fragment file
          @manifest.chapters.each do |chapter|
            # update cross-chapter refs
            chapter.nodes.each do |node|
              node.css('a.hyperref').each do |ref_node|
                # todo: pull finder to poly-core
                target = xml.xpath("//*[@id='#{ref_node['href'][1..-1]}']")
                unless target.empty?
                  target = target.first
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
          end
        end

        true
      end

      def clean!
        FileUtils.rm_rf "html"
      end

    end
  end
end
