module Polytexnic
  FORMATS = %w{html pdf epub mobi}
  BUILD_ALL_FORMATS = %w{pdf mobi}  # mobi calls epub, which calls html
end
