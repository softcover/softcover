module Softcover
  module Builders
    class Epub < Builder
      include Softcover::Output

      def build!(options={})
        @preview = options[:preview]
        Softcover::Builders::Html.new.build!
        if manifest.markdown?
          self.manifest = Softcover::BookManifest.new(source: :polytex,
                                                      origin: :markdown)
        end
        remove_html
        create_directories
        write_mimetype
        write_container_xml
        write_toc
        write_nav
        copy_image_files
        write_html(options)
        write_contents
        create_style_files
        make_epub(options)
        move_epub
      end

      # Returns true if generating a book preview.
      def preview?
        !!@preview
      end

      # Removes HTML.
      # All the HTML is generated, so this clears out any unused files.
      def remove_html
        FileUtils.rm(Dir.glob(path('epub/OEBPS/*.html')))
      end

      def create_directories
        mkdir('epub')
        mkdir(path('epub/OEBPS'))
        mkdir(path('epub/OEBPS/styles'))
        mkdir(path('epub/META-INF'))
        mkdir('ebooks')
      end

      # Writes the mimetype file.
      # This is required by the EPUB standard.
      def write_mimetype
        File.write(path('epub/mimetype'), 'application/epub+zip')
      end

      # Writes the container XML file.
      # This is required by the EPUB standard.
      def write_container_xml
        File.write(path('epub/META-INF/container.xml'), container_xml)
      end

      # Writes the content.opf file.
      # This is required by the EPUB standard.
      def write_contents
        File.write(path('epub/OEBPS/content.opf'), content_opf)
      end

      # Returns the chapters to write (accounting for previews).
      def chapters
        preview? ? manifest.preview_chapters : manifest.chapters
      end

      # Writes the HTML for the EPUB.
      # Included is a math detector that processes the page with MathJax
      # (via page.js) so that math can be included in EPUB (and thence MOBI).
      def write_html(options={})
        images_dir  = File.join('epub', 'OEBPS', 'images')
        texmath_dir = File.join(images_dir, 'texmath')
        mkdir images_dir
        mkdir texmath_dir

        File.write(path('epub/OEBPS/cover.html'), cover_page)

        pngs = []
        chapters.each_with_index do |chapter, i|
          target_filename = path("epub/OEBPS/#{chapter.fragment_name}")
          File.open(target_filename, 'w') do |f|
            content = File.read(path("html/#{chapter.fragment_name}"))
            doc = strip_attributes(Nokogiri::HTML(content))
            inner_html = doc.at_css('body').children.to_xhtml
            if math?(inner_html)
              html = html_with_math(chapter, images_dir, texmath_dir, pngs,
                                    options)
              html ||= inner_html # handle case of spurious math detection
            else
              html = inner_html
            end
            f.write(chapter_template("Chapter #{i}", html))
          end
        end
        # Clean up unused PNGs.
        png_files = Dir[path("#{texmath_dir}/*.png")]
        (png_files - pngs).each do |f|
          if File.exist?(f)
            puts "Removing unused PNG #{f}" unless options[:silent]
            FileUtils.rm(f)
          end
        end
      end

      # Returns HTML for HTML source that includes math.
      # As a side-effect, html_with_math creates PNGs corresponding to any
      # math in the given source. The technique involves using PhantomJS to
      # hit the HTML source for each page containing math to create SVGs
      # for every math element. Since ereader support for SVGs is spotty,
      # they are then converted to PNGs using Inkscape. The filenames are
      # SHAs of their contents, which arranges both for unique filenames
      # and for automatic disk caching.
      def html_with_math(chapter, images_dir, texmath_dir, pngs, options={})
        content = File.read(File.join("html", "#{chapter.slug}.html"))
        pagejs = "#{File.dirname(__FILE__)}/utils/page.js"
        url = "file://#{Dir.pwd}/html/#{chapter.slug}.html"
        cmd = "#{phantomjs} #{pagejs} #{url}"
        silence { silence_stream(STDERR) { system cmd } }
        # Sometimes in tests the phantomjs_source.html file is missing.
        # It shouldn't ever happen, but it does no harm to skip it.
        return nil unless File.exist?('phantomjs_source.html')
        raw_source = File.read('phantomjs_source.html')
        source = strip_attributes(Nokogiri::HTML(raw_source))
        rm 'phantomjs_source.html'
        # Remove the first body div, which is the hidden MathJax SVGs.
        if (mathjax_svgs = source.at_css('body div'))
          mathjax_svgs.remove
        else
          # There's not actually any math, so return nil.
          return nil
        end
        # Remove all the unneeded raw TeX displays.
        source.css('script').each(&:remove)
        # Remove all the MathJax preview spans.
        source.css('MathJax_Preview').each(&:remove)

        # Suck out all the SVGs
        svgs   = source.css('div#book svg')
        frames = source.css('span.MathJax_SVG')
        svgs.zip(frames).each do |svg, frame|
          # Save the SVG file.
          svg['viewBox'] = svg['viewbox']
          svg.remove_attribute('viewbox')
          first_child = frame.children.first
          first_child.replace(svg) unless svg == first_child
          output = svg.to_xhtml
          svg_filename = File.join(texmath_dir, "#{digest(output)}.svg")
          File.write(svg_filename, output)
          # Convert to PNG.
          png_filename = svg_filename.sub('.svg', '.png')
          pngs << png_filename
          unless File.exist?(png_filename)
            unless options[:silent] || options[:quiet]
              puts "Creating #{png_filename}"
            end
            svg_height = svg['style'].scan(/height: (.*?);/).flatten.first
            scale_factor = 8   # This scale factor turns out to look good.
            h = scale_factor * svg_height.to_f
            cmd = "#{inkscape} -f #{svg_filename} -e #{png_filename} -h #{h}pt"
            if options[:silent]
              silence { silence_stream(STDERR) { system cmd } }
            else
              silence_stream(STDERR) { system cmd }
            end
          end
          rm svg_filename
          png = Nokogiri::XML::Node.new('img', source)
          png['src'] = File.join('images', 'texmath',
                                 File.basename(png_filename))
          png['alt'] = png_filename.sub('.png', '')
          svg.replace(png)
        end
        source.at_css('div#book').children.to_xhtml
      end

      # Returns the PhantomJS executable (if available).
      def phantomjs
        @phantomjs ||= executable(dependency_filename(:phantomjs))
      end

      # Returns the Inkscape executable (if available).
      def inkscape
        @inkscape ||= executable(dependency_filename(:inkscape))
      end

      # Strip attributes that are invalid in EPUB documents.
      def strip_attributes(doc)
        attrs = %w[data-tralics-id data-label data-number data-chapter
                   role aria-readonly]
        doc.tap do
          attrs.each do |attr|
            doc.xpath("//@#{attr}").remove
          end
        end
      end

      # Returns true if a string appears to have LaTeX math.
      # We detect math via opening math commands: \(, \[, and \begin{equation}
      # This gives a false positive when math is included in verbatim
      # environments and nowhere else, but it does little harm (requiring only
      # an unnecessary call to page.js).
      def math?(string)
        !!string.match(/(?:\\\(|\\\[|\\begin{equation})/)
      end

      def create_style_files
        html_styles = File.join('html', 'stylesheets')
        epub_styles = File.join('epub', 'OEBPS', 'styles')

        FileUtils.cp(File.join(html_styles, 'pygments.css'), epub_styles)
        File.write(File.join(epub_styles, 'softcover.css'),
                   clean_book_id(path("#{html_styles}/softcover.css")))

        # Copy over the EPUB-specific CSS.
        template_dir = File.join(File.dirname(__FILE__), '..', 'template')
        epub_css     = File.join(template_dir, epub_styles, 'epub.css')
        FileUtils.cp(epub_css, epub_styles)

        # Copy over custom CSS.
        File.write(File.join(epub_styles, 'custom.css'),
                   clean_book_id(path("#{html_styles}/custom.css")))
      end

      # Removes the '#book' CSS id.
      # For some reason, EPUB books hate the #book ids in the stylesheet
      # (i.e., such books fail to validate), so remove them.
      def clean_book_id(filename)
        File.read(filename).gsub(/#book/, '')
      end

      # Copies the image files from the HTML version of the document.
      # We remove PDF images, which are valid in PDF documents but not in EPUB.
      def copy_image_files
        FileUtils.cp_r(File.join('html', 'images'),
                       File.join('epub', 'OEBPS'))
        File.delete(*Dir['epub/OEBPS/images/**/*.pdf'])
      end

      # Make the EPUB, which is basically just a zipped HTML file.
      def make_epub(options={})
        filename = manifest.filename
        zip_filename = filename + '.zip'
        base_file = "zip -X0    #{zip_filename} mimetype"
        zip = "zip -rDXg9"
        meta_info = "#{zip} #{zip_filename} META-INF -x \*.DS_Store -x mimetype"
        main_info = "#{zip} #{zip_filename} OEBPS    -x \*.DS_Store \*.gitkeep"
        rename = "mv #{zip_filename} #{filename}.epub"
        commands = [base_file, meta_info, main_info, rename]
        command = commands.join(' && ')
        Dir.chdir('epub') do
          if Softcover.test? || options[:quiet] || options[:silent]
            silence { system(command) }
          else
            system(command)
          end
        end
      end

      # Move the completed EPUB book to the `ebooks` directory.
      # Note that we handle the case of a preview book as well.
      def move_epub
        origin = manifest.filename
        target = preview? ? origin + '-preview' : origin
        FileUtils.mv(File.join('epub',   "#{origin}.epub"),
                     File.join('ebooks', "#{target}.epub"))
      end

      # Writes the Table of Contents.
      # This is required by the EPUB standard.
      def write_toc
        File.write('epub/OEBPS/toc.ncx', toc_ncx)
      end

      # Writes the navigation file.
      # This is required by the EPUB standard.
      def write_nav
        File.write('epub/OEBPS/nav.html', nav_html)
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
        man_ch = chapters.map do |chapter|
                   %(<item id="#{chapter.slug}" href="#{chapter.fragment_name}" media-type="application/xhtml+xml"/>)
                 end
        toc_ch = chapters.map do |chapter|
                   %(<itemref idref="#{chapter.slug}"/>)
                 end
        image_files = Dir['epub/OEBPS/images/**/*'].select { |f| File.file?(f) }
        images = image_files.map do |image|
                   ext = File.extname(image).sub('.', '')   # e.g., 'png'
                   # Strip off the leading 'epub/OEBPS'.
                   sep  = File::SEPARATOR
                   href = image.split(sep)[2..-1].join(sep)
                   # Define an id based on the filename.
                   # Prefix with 'img-' in case the filname starts with an
                   # invalid character such as a number.
                   label = File.basename(image).gsub('.', '-')
                   id = "img-#{label}"
                   %(<item id="#{id}" href="#{href}" media-type="image/#{ext}"/>)
                 end
%(<?xml version="1.0" encoding="UTF-8"?>
  <package unique-identifier="BookID" version="3.0" xmlns="http://www.idpf.org/2007/opf">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
        xmlns:opf="http://www.idpf.org/2007/opf">
        <dc:title>#{title}</dc:title>
        <dc:language>en</dc:language>
        <dc:rights>Copyright (c) #{copyright} #{author}</dc:rights>
        <dc:creator>#{author}</dc:creator>
        <dc:publisher>Softcover</dc:publisher>
        <dc:identifier id="BookID">urn:uuid:#{uuid}</dc:identifier>
        <meta property="dcterms:modified">#{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}Z</meta>
        <meta name="cover" content="img-cover-png"/>
    </metadata>
    <manifest>
        <item href="nav.html" id="nav" media-type="application/xhtml+xml" properties="nav"/>
        <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
        <item id="page-template.xpgt" href="styles/page-template.xpgt" media-type="application/vnd.adobe-page-template+xml"/>
        <item id="pygments.css" href="styles/pygments.css" media-type="text/css"/>
        <item id="softcover.css" href="styles/softcover.css" media-type="text/css"/>
        <item id="epub.css" href="styles/epub.css" media-type="text/css"/>
        <item id="custom.css" href="styles/custom.css" media-type="text/css"/>
        <item id="cover" href="cover.html" media-type="application/xhtml+xml"/>
        #{man_ch.join("\n")}
        #{images.join("\n")}
    </manifest>
    <spine toc="ncx">
      <itemref idref="cover" linear="no" />
      #{toc_ch.join("\n")}
    </spine>
  </package>
)
      end

      def cover_page
%(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Cover</title>
</head>
<body>
  <div id="cover">
     <img width="573" height="800" src="images/cover.png" alt="cover image" />
  </div>
</body>
</html>
)
      end

      # Returns the Table of Contents for the spine.
      def toc_ncx
        title = manifest.title
        chapter_nav = []
        offset = preview? ? manifest.preview_chapter_range.first : 0
        chapters.each_with_index do |chapter, i|
          n = i + offset
          chapter_nav << %(<navPoint id="#{chapter.slug}" playOrder="#{n+1}">)
          chapter_nav << %(    <navLabel><text>#{chapter_name(n)}</text></navLabel>)
          chapter_nav << %(    <content src="#{chapter.fragment_name}"/>)
          chapter_nav << %(</navPoint>)
        end
%(<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
    <head>
        <meta name="dtb:uid" content="#{manifest.uuid}"/>
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
</ncx>
)
      end

      def chapter_name(n)
        n == 0 ? "Frontmatter" : "Chapter #{n}"
      end

      # Returns the nav HTML content.
      def nav_html
        title = manifest.title
        nav_list = manifest.chapters.map do |chapter|
                     %(<li><a href="#{chapter.fragment_name}">#{chapter.title}</a></li>)
                   end
%(<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
        <meta charset="UTF-8" />
        <title>#{title}</title>
    </head>
    <body>
        <nav epub:type="toc">
            <h1>#{title}</h1>
            <ol>
              #{nav_list.join("\n")}
            </ol>
        </nav>
    </body>
</html>
)
      end

      # Returns the HTML template for a chapter.
      def chapter_template(title, content)
        %(<?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE html>

        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{title}</title>
          <link rel="stylesheet" href="styles/pygments.css" type="text/css" />
          <link rel="stylesheet" href="styles/softcover.css" type="text/css" />
          <link rel="stylesheet" href="styles/epub.css" type="text/css" />
          <link rel="stylesheet" href="styles/custom.css" type="text/css"/>
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