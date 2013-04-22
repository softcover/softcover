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
        copy_stylesheets
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
        html_path = File.join('html', manifest.filename + '.html')
        raw_content = File.open(html_path).read
        content = Nokogiri::HTML(raw_content).at_css('body').inner_html
        File.open("epub/OEBPS/#{manifest.filename}.html", 'w') do |f|
          f.write(template(manifest.title, content))
        end
        File.open('epub/OEBPS/content.opf', 'w') { |f| f.write(content_opf) }
      end

      def copy_stylesheets
        FileUtils.cp(File.join('html', 'stylesheets', 'pygments.css'),
                     File.join('epub', 'OEBPS', 'styles'))
      end

      # Make the EPUB, which is basically just a zipped HTML file.
      def make_epub
        filename = manifest.filename
        zip_filename = filename + '.zip'
        base_file = "zip -X0    #{zip_filename} mimetype"
        meta_info = "zip -rDXg9 #{zip_filename} META-INF -x \*.DS_Store -x mimetype"
        main_info = "zip -rDXg9 #{zip_filename} OEBPS    -x \*.DS_Store"
        rename = "mv #{zip_filename} #{filename}.epub"
        commands = [base_file, meta_info, main_info, rename]
        commands.map! { |c| c += ' > /dev/null' } if Polytexnic.test?

        Dir.chdir('epub') do
          system(commands.join(' && '))
        end
      end

      def write_toc
        File.open('epub/OEBPS/toc.ncx',  'w') { |f| f.write(toc_ncx) }
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

      # This is hard-coded for now, but will eventually be dynamic.
      def content_opf
%(<?xml version="1.0" encoding="UTF-8"?>
  <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
          <dc:title>Foo Bar</dc:title>
    <dc:language>en</dc:language>
          <dc:rights>Copyright 2012 Michael Hartl</dc:rights>
          <dc:creator opf:role="aut">Michael Hartl</dc:creator>
          <dc:publisher>Softcover</dc:publisher>
          <dc:identifier id="BookID" opf:scheme="UUID">d430b920-e684-11e1-aff1-0800200c9a66</dc:identifier>
      </metadata>
      <manifest>
          <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
          <item id="page-template.xpgt" href="styles/page-template.xpgt" media-type="application/vnd.adobe-page-template+xml"/>
          <item id="sec-1" href="#{manifest.filename}.html" media-type="application/xhtml+xml"/>
          <item id="toc" href="toc.html" media-type="application/xhtml+xml"/>
          <item id="pygments.css" href="styles/pygments.css" media-type="text/css"/>
      </manifest>
      <spine toc="ncx">
<itemref idref="toc"/>
<itemref idref="sec-1"/>
      </spine>
      <guide>
        <reference type="toc" title="Table of Contents" href="toc.html"/>
      </guide>
  </package>)
      end

      # This is hard-coded for now, but will eventually be dynamic.
      def toc_ncx
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
        <text>Foo Bar</text>
    </docTitle>
    <navMap>
        <navPoint id="navPoint-1" playOrder="1">
            <navLabel>
                <text>Detailed Table of Contents</text>
            </navLabel>
            <content src="toc.html" />
        </navPoint>
            <navPoint id="sec-1" playOrder="2">
            <navLabel><text>Chapter Foo</text></navLabel>
            <content src="#{manifest.filename}.html"/>
    </navPoint>
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

    end
  end
end