module Polytexnic
  module Mathjax
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
        },
        showProcessingMessages: false,
        messageStyle: "none",
        imageFont: null
      });
      EOS
    end

    MATHJAX  = 'MathJax/MathJax.js?config='
    AMS_HTML = '/' + MATHJAX + 'TeX-AMS_HTML'
    AMS_SVG  = MATHJAX + 'TeX-AMS-MML_SVG'
  end
end
