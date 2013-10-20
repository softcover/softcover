module Polytexnic
  module Mathjax

    # Returns the MathJax configuration.
    def self.config(options = {})
      chapter_number = if options[:chapter_number]
                         options[:chapter_number].inspect.inspect
                       else
                         '#{chapter_number}'
                       end
      <<-EOS
      MathJax.Hub.Config({
        "HTML-CSS": {
          availableFonts: ["TeX"],
        },
        TeX: {
          extensions: ["AMSmath.js", "AMSsymbols.js"],
          equationNumbers: {
            autoNumber: "AMS",
            formatNumber: function (n) { return #{chapter_number} + '.' + n }
          },
          Macros: {
            PolyTeX:    "Poly{\\\\TeX}",
            PolyTeXnic: "Poly{\\\\TeX}nic",
            #{custom_macros}
          }
        },
        showProcessingMessages: false,
        messageStyle: "none",
        imageFont: null
      });
      EOS
    end

    # Rerturns a version of the MathJax configuration escaped for the server.
    # There's an extra interpolation somewhere between here and the server,
    # which this method corrects for.
    def self.escaped_config
      self.config.gsub('\\', '\\\\\\\\')
    end

    MATHJAX  = 'MathJax/MathJax.js?config='
    AMS_HTML = '/' + MATHJAX + 'TeX-AMS_HTML'
    AMS_SVG  = MATHJAX + 'TeX-AMS-MML_SVG'


    private

      # Returns the custom macros as defined in the custom style file.
      def self.custom_macros
        extract_macros(File.read('custom.sty')) rescue ''
      end

      # Extracts and formats the macros from the given string of style commands.
      # The output format is compatible with the macros configuration described
      # at http://docs.mathjax.org/en/latest/tex.html.
      def self.extract_macros(styles)
        # For some reason, \ensuremath doesn't work in MathJax, so remove it.
        styles.gsub!('\ensuremath', '')
        # First extract commands with no arguments.
        cmd_no_args = /^\s*\\newcommand\{\\(.*?)\}\{(.*)\}/
        cna = styles.scan(cmd_no_args).map do |name, definition|
          escaped_definition = definition.gsub('\\', '\\\\\\\\')
          %(#{name}: "#{escaped_definition}")
        end
        # Then grab the commands with arguments.
        cmd_with_args = /^\s*\\newcommand\{\\(.*?)\}\[(\d+)\]\{(.*)\}/
        cwa = styles.scan(cmd_with_args).map do |name, number, definition|
          escaped_definition = definition.gsub('\\', '\\\\\\\\')
          %(#{name}: ["#{escaped_definition}", #{number}])
        end
        (cna + cwa).join(",\n")
      end
  end
end
