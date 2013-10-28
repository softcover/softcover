module Polytexnic
  FORMATS = %w{html epub mobi pdf}
  # mobi calls epub, which calls html, so "all formats" is just mobi & pdf.
  BUILD_ALL_FORMATS = %w{mobi pdf}
end
