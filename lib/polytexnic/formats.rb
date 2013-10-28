module Polytexnic
  FORMATS = %w{html epub mobi pdf}
  BUILD_ALL_FORMATS = %w{mobi pdf}  # mobi calls epub, which calls html
end
