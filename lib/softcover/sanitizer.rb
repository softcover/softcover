require 'sanitize'

module Softcover
  module Sanitizer
    extend self

    # Sanitization suitable for displaying untrusted generated html, while
    # retaining useful tags and attributes.

    def clean(html)
      return unless html

      # Make a whitelist of acceptable elements and attributes.
      sanitize_options = {
        elements: %w{div span p a ul ol li h1 h2 h3 h4
                     pre em sup table tbody thead tr td img code strong
                     blockquote small br section aside},
        remove_contents: %w{script},
        attributes: {
          'div' => %w{id class data-tralics-id data-number data-chapter},
          'a'    => %w{id class href target rel},
          'span' => %w{id class style},
          'ol'   => %w{id class},
          'ul'   => %w{id class},
          'li'   => %w{id class},
          'sup'  => %w{id class},
          'h1'   => %w{id class},
          'h2'   => %w{id class},
          'h3'   => %w{id class},
          'h4'   => %w{id class},
          'img'  => %w{id class src alt},
          'em'   => %w{id class},
          'code' => %w{id class},
          'section' => %w{id class},
          'aside' => %w{id class},
          'blockquote' => %w{id class},
          'br' => %w{id class},
          'strong' => %w{id class},
          'table'   => %w{id class},
          'tbody'   => %w{id class},
          'tr'   => %w{id class},
          'td'   => %w{id class colspan}
        },
        css: {
          properties: %w{color height width}
        },
        protocols: {
          'a'   => {'href' => [:relative, 'http', 'https', 'mailto']},
          'img' => {'src'  => [:relative, 'http', 'https']}
        },
        output: :xhtml
      }

      Sanitize.clean(html.force_encoding("UTF-8"), sanitize_options)
    end
  end
end
