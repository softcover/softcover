module Softcover::Output
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
      if Softcover::Output.should_output?(options[:level])
        Softcover::Output.stream.send method, string
      end
    end
  end

  def system(cmd)
    output = `#{cmd}`
    puts output
  end
end
