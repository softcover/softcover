module Polytexnic
  module Builders
    class Epub < Builder

      def build!
        Dir.mkdir('epub') unless File.directory?('epub')
        Dir.mkdir('epub/OEBPS') unless File.directory?('epub/OEBPS')
        Dir.mkdir('epub/META-INF') unless File.directory?('epub/META-INF')
        File.open('epub/mimetype', 'w') { |f| f.write('application/epub+zip') }
        # raise manifest.filename
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

    end
  end
end