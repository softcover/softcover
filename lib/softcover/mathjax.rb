module Softcover
  module Mathjax

    # Returns the MathJax configuration.
    def self.config(options = {})
      chapter_number = if options[:chapter_number]
                         if (options[:chapter_number].zero? ||
                             Softcover::Utils.article?)
                             false
                           else
                             # Call .inspect.inspect to escape the chapter
                             # number code for interpolation.
                             options[:chapter_number].inspect.inspect
                           end
                         elsif options[:chapter_number].nil?
                           '#{chapter_number}'
                       else  # chapter_number is false, i.e., it's a single page
                         false
                       end
      fn = if chapter_number
             "formatNumber: function (n) { return #{chapter_number} + '.' + n }"
           else
             ""
           end

      config = <<-EOS
      MathJax.Hub.Config({
        "HTML-CSS": {
          availableFonts: ["TeX"],
        },
        TeX: {
          extensions: ["AMSmath.js", "AMSsymbols.js", "color.js"],
          equationNumbers: {
            autoNumber: "AMS",
            #{fn}
          },
          Macros: {
            PolyTeX:    "Poly{\\\\TeX}",
            PolyTeXnic: "Poly{\\\\TeX}nic",
            #{custom_macros}
          }
        },
        showProcessingMessages: false,
        messageStyle: "none",
        imageFont: null,
        "AssistiveMML": { disabled: true }
      });
      EOS
      config
    end

    # Rerturns a version of the MathJax configuration escaped for the server.
    # There's an extra interpolation somewhere between here and the server,
    # which this method corrects for.
    def self.escaped_config(options={})
      self.config(options).gsub('\\', '\\\\\\\\')
    end

    MATHJAX  = 'https://cdn.mathjax.org/mathjax/latest/MathJax.js?config='
    AMS_HTML = MATHJAX + 'TeX-AMS_HTML'
    AMS_SVG  = MATHJAX + 'TeX-AMS-MML_SVG'

    # Returns the custom macros as defined in the custom style file.
    def self.custom_macros
      extract_macros(Softcover.custom_styles)
    end

    private

      # Extracts and formats the macros from the given string of style commands.
      # The output format is compatible with the macro configuration described
      # at http://docs.mathjax.org/en/latest/tex.html.
      def self.extract_macros(styles)
        # For some reason, \ensuremath doesn't work in MathJax, so remove it.
        styles.gsub!('\ensuremath', '')
        # First extract commands with no arguments.
        cmd_no_args = /^\s*\\newcommand\{\\(.*?)\}\{(.*)\}/
        cna = styles.scan(cmd_no_args).map do |name, definition|
          escaped_definition = definition.gsub('\\', '\\\\\\\\')
          %("#{name}": "#{escaped_definition}")
        end
        # Then grab the commands with arguments.
        cmd_with_args = /^\s*\\newcommand\{\\(.*?)\}\[(\d+)\]\{(.*)\}/
        cwa = styles.scan(cmd_with_args).map do |name, number, definition|
          escaped_definition = definition.gsub('\\', '\\\\\\\\')
          %("#{name}": ["#{escaped_definition}", #{number}])
        end
        (cna + cwa).join(",\n")
      end
  end
end
