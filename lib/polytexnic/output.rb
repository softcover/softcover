module Polytexnic::Output
  class << self
    attr_accessor :silent, :stream, :verbosity_level

    def stream
      silent? ? StringIO.new : (defined?(@stream) && @stream) || $stdout
    end

    def silence!
      @silent = true
    end

    def unsilence!
      @silent = false
    end

    def silent?
      defined?(@silent) && @silent
    end

    def should_output?(level)
      !silent? ||
      !(level && defined?(@verbosity_level) && level < @verbosity_level)
    end
  end

  %w{puts printf print}.each do |method|
    define_method method do |string, options={}|
      if Polytexnic::Output.should_output?(options[:level])
        Polytexnic::Output.stream.send method, string
      end
    end
  end

  def system(cmd)
    output = `#{cmd}`
    puts output
  end
end
