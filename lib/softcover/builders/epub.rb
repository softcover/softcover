module Softcover

  module EpubUtils

    # Returns the name of the cover file.
    # We support (in order) JPG/JPEG, PNG, and TIFF.
    def cover_img
      extensions = %w[jpg jpeg png tiff]
      extensions.each do |ext|
        origin = "images/cover.#{ext}"
        target = "#{images_dir}/cover.#{ext}"
        if File.exist?(origin)
          FileUtils.cp(origin, target)
          return File.basename(target)
        end
      end
      return false
    end

    def cover?
      cover_img
    end

    def cover_img_path
      path("#{images_dir}/#{cover_img}")
    end

    def images_dir
      path('epub/OEBPS/images')
    end
  end

  module Builders
    class Epub < Builder
      include Softcover::Output
      include Softcover::EpubUtils

      def build!(options={})
        @preview = options[:preview]
        Softcover::Builders::Html.new.build!
        if manifest.markdown?
          opts = options.merge({ source: :polytex, origin: :markdown })
          self.manifest = Softcover::BookManifest.new(opts)
        end
        remove_html
        remove_images
        create_directories
        write_mimetype
        write_container_xml
        write_ibooks_xml
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

      # Removes images in case they are stale.
      def remove_images
        rm_r images_dir
      end

      def create_directories
        mkdir('epub')
        mkdir(path('epub/OEBPS'))
        mkdir(path('epub/OEBPS/styles'))
        mkdir(path('epub/META-INF'))
        mkdir(images_dir)
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

      # Writes iBooks-specific XML.
      # This allows proper display of monospace fonts in code samples, among
      # other things.
      def write_ibooks_xml
        xml_filename = 'com.apple.ibooks.display-options.xml'
        File.write(path("epub/META-INF/#{xml_filename}"), ibooks_xml)
      end

      # Writes the content.opf file.
      # This is required by the EPUB standard.
      def write_contents
        File.write(path('epub/OEBPS/content.opf'), content_opf)
      end

      # Returns the chapters to write.
      def chapters
        preview? ? manifest.preview_chapters : manifest.chapters
      end

      # Writes the HTML for the EPUB.
      # Included is a math detector that processes the page with MathJax
      # (via page.js) so that math can be included in EPUB (and thence MOBI).
      def write_html(options={})
        texmath_dir = File.join(images_dir, 'texmath')
        mkdir images_dir
        mkdir texmath_dir

        File.write(path('epub/OEBPS/cover.html'), cover_page) if cover?

        pngs = []
        puts chapters
        chapters.each_with_index do |chapter, i|
          target_filename = path("epub/OEBPS/#{chapter.fragment_name}")
          puts target_filename
          File.open(target_filename, 'w') do |f|
            #puts "writing html for file:"
            #puts "#{chapter.fragment_name}"
            content = File.read(path("html/#{chapter.fragment_name}"))
            doc = strip_attributes(Nokogiri::HTML(content))
            body = doc.at_css('body')
            if body.nil?
              $stderr.puts "\nError: Document not built due to empty chapter"
              $stderr.puts "Chapters must include a title using the Markdown"
              $stderr.puts "    # This is a chapter"
              $stderr.puts "or the LaTeX"
              $stderr.puts "    \\chapter{This is a chapter}"
              exit(1)
            end
            inner_html = body.children.to_xhtml
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
                   role aria-readonly target]
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
      def copy_image_files
        # Copy over all images to guarantee the same directory structure.
        FileUtils.cp_r(File.join('html', 'images'),
                       File.join('epub', 'OEBPS'))
        # Parse the full HTML file with Nokogiri to get images actually used.
        html = File.read(manifest.full_html_file)
        html_image_filenames = Nokogiri::HTML(html).css('img').map do |node|
                                 node.attributes['src'].value
                               end
        # Form the corresponding EPUB image paths.
        used_image_filenames = html_image_filenames.map do |filename|
                                 "epub/OEBPS/#{filename}"
                               end.to_set
        # Delete unused images.
        Dir.glob("epub/OEBPS/images/**/*").each do |image|
          next if File.directory?(image)
          rm image unless used_image_filenames.include?(image)
        end
      end

      # Make the EPUB, which is basically just a zipped HTML file.
      def make_epub(options={})
        filename = manifest.filename
        zfname = filename + '.zip'
        base_file = "#{zip} -X0 #{zfname} mimetype"
        fullzip = "#{zip} -rDXg9"
        meta_info = "#{fullzip} #{zfname} META-INF -x \*.DS_Store -x mimetype"
        main_info = "#{fullzip} #{zfname} OEBPS    -x \*.DS_Store \*.gitkeep"
        rename = "mv #{zfname} #{filename}.epub"
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

      def zip
        @zip ||= executable(dependency_filename(:zip))
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

      def ibooks_xml
%(<?xml version="1.0" encoding="UTF-8"?>
<display_options>
  <platform name="*">
    <option name="specified-fonts">true</option>
  </platform>
</display_options>)
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
                   ext = 'jpeg' if ext == 'jpg'
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
        <meta name="cover" content="#{cover_id}"/>
    </metadata>
    <manifest>
        <item href="nav.html" id="nav" media-type="application/xhtml+xml" properties="nav"/>
        <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
        <item id="page-template.xpgt" href="styles/page-template.xpgt" media-type="application/vnd.adobe-page-template+xml"/>
        <item id="pygments.css" href="styles/pygments.css" media-type="text/css"/>
        <item id="softcover.css" href="styles/softcover.css" media-type="text/css"/>
        <item id="epub.css" href="styles/epub.css" media-type="text/css"/>
        <item id="custom.css" href="styles/custom.css" media-type="text/css"/>
        <item id="custom_epub.css" href="styles/custom_epub.css" media-type="text/css"/>
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
     <img width="573" height="800" src="images/#{cover_img}" alt="cover" />
  </div>
</body>
</html>
)
      end

      def cover_id
        "img-#{cover_img.sub('.', '-')}"
      end

      # Returns the Table of Contents for the spine.
      def toc_ncx
        title = manifest.title
        chapter_nav = []
        chapters.each_with_index do |chapter, n|
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
        n == 0 ? language_labels["frontmatter"] : chapter_label(n)
      end

      # Returns the nav HTML content.
      def nav_html
        title = manifest.title
        nav_list = manifest.chapters.map do |chapter|
                     element = preview? ? chapter.title : nav_link(chapter)
                     %(<li>#{element}</li>)
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

      # Returns a navigation link for the chapter.
      def nav_link(chapter)
        %(<a href="#{chapter.fragment_name}">#{chapter.title}</a>)
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
          <link rel="stylesheet" href="styles/custom_epub.css" type="text/css"/>
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
