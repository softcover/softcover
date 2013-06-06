module Polytexnic
  module Builders
    class Epub < Builder

      def build!
        build_html
        create_directories
        write_mimetype
        write_container_xml
        write_contents
        write_toc
        create_html
        create_style_files
        copy_image_files
        make_epub
      end

      def build_html
        Polytexnic::Builders::Html.new.build!
      end

      def create_directories
        mkdir('epub')
        mkdir('epub/OEBPS')
        mkdir('epub/OEBPS/styles')
        mkdir('epub/META-INF')
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
        File.open('epub/OEBPS/content.opf', 'w') { |f| f.write(content_opf) }
      end

      def create_html
        manifest.chapters.each_with_index do |chapter, i|
          source_filename = File.join('epub', 'OEBPS', chapter.fragment_name)
          File.open(source_filename, 'w') do |f|
            content = File.read("html/#{chapter.fragment_name}")

            # strip data attributes
            doc = Nokogiri::HTML(content)
            %w{tralics-id label number chapter}.each do |attr|
              doc.xpath("//@data-#{attr}").remove
            end

            # add .html to links
            # doc.css('a.ref').each do |node|
            #   node
            # end

            html = doc.at_css('body').children.to_xhtml
            f.write(chapter_template("Chapter #{i+1}", html))
          end
        end
      end

      def create_style_files
        FileUtils.cp(File.join('html', 'stylesheets', 'pygments.css'),
                     File.join('epub', 'OEBPS', 'styles'))
      end

      def copy_image_files
        FileUtils.cp_r(File.join('html', 'images'),
                       File.join('epub', 'OEBPS'))
      end

      # Make the EPUB, which is basically just a zipped HTML file.
      def make_epub
        filename = manifest.filename
        zip_filename = filename + '.zip'
        base_file = "zip -X0    #{zip_filename} mimetype"
        zip = "zip -rDXg9"
        meta_info = "#{zip} #{zip_filename} META-INF -x \*.DS_Store -x mimetype"
        main_info = "#{zip} #{zip_filename} OEBPS    -x \*.DS_Store \*.gitkeep"
        rename = "mv #{zip_filename} #{filename}.epub"
        commands = [base_file, meta_info, main_info, rename]
        commands.map! { |c| c += ' > /dev/null' } if Polytexnic.test?

        Dir.chdir('epub') do
          system(commands.join(' && '))
        end
      end

      def write_toc
        File.open('epub/OEBPS/toc.ncx', 'w') { |f| f.write(toc_ncx) }
      end

      def mkdir(dir)
        Dir.mkdir(dir) unless File.directory?(dir)
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

      # Returns the content configuration file.
      def content_opf
        title  = manifest.title
        author = manifest.author
        copyright = manifest.copyright
        uuid = manifest.uuid
        man_ch = manifest.chapters.map do |chapter|
                   %(<item id="#{chapter.slug}" href="#{chapter.fragment_name}" media-type="application/xhtml+xml"/>)
                 end
        toc_ch = manifest.chapters.map do |chapter|
                   %(<itemref idref="#{chapter.slug}"/>)
                 end
        images = Dir['images/**/*'].select { |f| File.file?(f) }.map do |image|
                   ext = File.extname(image).sub('.', '')   # e.g., 'png'
                   %(<item id="#{File.basename(image)}" href="#{image}" media-type="image/#{ext}"/>)
                 end
%(<?xml version="1.0" encoding="UTF-8"?>
  <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
          <dc:title>#{title}</dc:title>
    <dc:language>en</dc:language>
          <dc:rights>Copyright (c) #{copyright} #{author}</dc:rights>
          <dc:creator opf:role="aut">#{author}</dc:creator>
          <dc:publisher>Softcover</dc:publisher>
          <dc:identifier id="BookID" opf:scheme="UUID">#{uuid}</dc:identifier>
      </metadata>
      <manifest>
          <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
          <item id="page-template.xpgt" href="styles/page-template.xpgt" media-type="application/vnd.adobe-page-template+xml"/>
          <item id="pygments.css" href="styles/pygments.css" media-type="text/css"/>
          <item id="polytexnic.css" href="styles/polytexnic.css" media-type="text/css"/>
          #{man_ch.join("\n")}
          #{images.join("\n")}
      </manifest>
      <spine toc="ncx">
        #{toc_ch.join("\n")}
      </spine>
      <guide>
      </guide>
  </package>)
      end

      # Returns the Table of Contents for the spine.
      def toc_ncx
        title = manifest.title
        chapter_nav = []
        manifest.chapters.each_with_index do |chapter, n|
          chapter_nav << %(<navPoint id="#{chapter.slug}" playOrder="#{n+1}">)
          chapter_nav << %(    <navLabel><text>Chapter #{n+1}</text></navLabel>)
          chapter_nav << %(    <content src="#{chapter.fragment_name}"/>)
          chapter_nav << %(</navPoint>)
        end

%(<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
   "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">

<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
    <head>
        <meta name="dtb:uid" content="d430b920-e684-11e1-aff1-0800200c9a66"/>
        <meta name="dtb:depth" content="2"/>
        <meta name="dtb:totalPageCount" content="0"/>
        <meta name="dtb:maxPageNumber" content="0"/>
    </head>
    <docTitle>
        <text>#{title}</text>
    </docTitle>
    <navMap>
      #{chapter_nav.join("\n")}
    </navMap>
</ncx>)
      end

      # This is hard-coded for now, but will eventually be dynamic.
      def toc_html
%(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Table of Contents</title>
  <link rel="stylesheet" type="application/vnd.adobe-page-template+xml" href="styles/page-template.xpgt" />
</head>

<body>

<h1 class="contents" id="toc">Table of Contents</h1>
<h1 class="contents" id="sec-1">Foo Bar</h1>
</body>
</html>)
      end

      # Returns the HTML template for a chapter.
      def chapter_template(title, content)
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
    end
  end
end