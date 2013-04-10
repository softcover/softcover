module Polytexnic
  module Builders
    class Epub < Builder

      def build!
        build_html
        create_directories
        write_mimetype
        write_container_xml
        write_contents
        make_epub
      end

      def template(title, content)
        %(<?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
          "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{title}</title>
          <link rel="stylesheet" href="styles/pygments.css" type="text/css" />
          <link rel="stylesheet" href="styles/polytexnic.css" type="text/css" />
          <link rel="stylesheet" type="application/vnd.adobe-page-template+xml" href="styles/page-template.xpgt" />
        </head>

        <body>
          #{content}
        </body>
        </html>)
      end

      def container_xml
%(<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>)        
      end

      def build_html
        Polytexnic::Builders::Html.new.build!
      end

      def create_directories
        Dir.mkdir('epub') unless File.directory?('epub')
        Dir.mkdir('epub/OEBPS') unless File.directory?('epub/OEBPS')
        Dir.mkdir('epub/META-INF') unless File.directory?('epub/META-INF')        
      end

      # Writes the mimetype file.
      # This is required by the EPUB standard.
      def write_mimetype
        File.open('epub/mimetype', 'w') { |f| f.write('application/epub+zip') }
      end

      # Writes the container XML file.
      # This is required by the EPUB standard.
      def write_container_xml
        File.open('epub/META-INF/container.xml', 'w') do |f|
          f.write(container_xml)
        end        
      end

      def write_contents
        content = File.open("html/#{manifest.filename}.html").read
        File.open("epub/OEBPS/#{manifest.filename}.html", 'w') do |f|
          f.write(template(manifest.title, content))
        end
      end

      # Make the EPUB, which is basically just a zipped HTML file.
      def make_epub
        filename = manifest.filename
        base_file = "zip -X0    #{filename} mimetype"
        meta_info = "zip -rDXg9 #{filename} META-INF -x \*.DS_Store -x mimetype"
        main_info = "zip -rDXg9 #{filename} OEBPS    -x \*.DS_Store"
        rename = "mv #{filename}.zip #{filename}.epub"
        commands = [base_file, meta_info, main_info, rename]
        commands.map! { |c| c += ' > /dev/null' } if Polytexnic.test?

        Dir.chdir('epub')
        system(commands.join(' && '))
      end
    end
  end
end