# Softcover

[![Build Status](https://travis-ci.org/softcover/softcover.png?branch=master)](https://travis-ci.org/softcover/softcover) [![Coverage Status](https://coveralls.io/repos/softcover/softcover/badge.png)](https://coveralls.io/r/softcover/softcover) [![Inline docs](http://inch-pages.github.io/github/softcover/softcover.png)](http://inch-pages.github.io/github/softcover/softcover)

Softcover is an ebook typesetting system for technical authors. This is the main gem, `softcover`, which depends on `polytexnic` to convert Markdown or PolyTeX input to HTML and LaTeX, and thence to EPUB, MOBI, and PDF. Authors can use Softcover to publish and optionally sell the resulting ebooks (as well as associated digital goods such as screencasts) on the [Softcover publishing platform](http://www.softcover.io/).

For more details about Softcover, see [*The Softcover Book*](http://manual.softcover.io/book).

<!--
# Softcover CLI

Command line interface for Softcover.io

## Installation

    $ gem install softcover

## Usage

    $ softcover <command>

## Commands:

* login
* logout
* build:html, build:pdf, build:epub, build:mobi, build:all
* build (aliased to build:html)
* publish
* new

## Development Notes
    $ softcover config:add host=http://localhost:3000

  * use "silence=false" to unsilence spec output:

    $ silence=false bundle exec rspec
-->
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
