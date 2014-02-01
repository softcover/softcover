require 'polytexnic'
require 'active_support/core_ext/string'

@profiling = false

require_relative 'softcover/formats'
require_relative 'softcover/utils'
require_relative 'softcover/output'
require_relative 'softcover/directories'

if @profiling
  times = []
  Dir[File.join(File.dirname(__FILE__), '/softcover/**/*.rb')].each do |file|
    t1 = Time.now
    next if file =~ /railtie/ && !defined?(Rails)
    require file.chomp(File.extname(file))
    times << "#{Time.now - t1} #{File.basename(file)}"
  end
  $stderr.puts times.sort.reverse
end

require_relative 'softcover/book'
require_relative 'softcover/book_manifest'
require_relative 'softcover/builder'
require_relative 'softcover/builders/epub'
require_relative 'softcover/builders/html'
require_relative 'softcover/builders/mobi'
require_relative 'softcover/builders/pdf'
require_relative 'softcover/builders/preview'
require_relative 'softcover/cli'
require_relative 'softcover/commands/auth'
require_relative 'softcover/commands/build'
require_relative 'softcover/commands/deployment'
require_relative 'softcover/commands/epub_validator'
require_relative 'softcover/commands/generator'
require_relative 'softcover/commands/opener'
require_relative 'softcover/commands/server'
require_relative 'softcover/mathjax'
require_relative 'softcover/uploader'
require_relative 'softcover/version'

module Softcover
  extend self

  include Softcover::Utils

  # Return the custom styles, if any.
  def custom_styles
    custom_file = File.join(Softcover::Directories::STYLES, 'custom.sty')
    File.exist?(custom_file) ? File.read(custom_file) : ''
  end

  def set_test_mode!
    @test_mode = true
  end

  def test?
    @test_mode
  end

  def profiling?
    return false if test?
    @profiling
  end
end

require 'softcover/rails/railtie' if defined?(Rails)
