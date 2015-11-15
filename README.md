# Softcover

<!-- [![Build Status](https://travis-ci.org/softcover/softcover.png?branch=master)](https://travis-ci.org/softcover/softcover) [![Coverage Status](https://coveralls.io/repos/softcover/softcover/badge.png)](https://coveralls.io/r/softcover/softcover)
 -->
Softcover is an ebook typesetting system for technical authors. This is the main gem, `softcover`, which depends on `polytexnic` to convert Markdown or PolyTeX input to HTML and LaTeX, and thence to EPUB, MOBI, and PDF. Authors can use Softcover to publish and optionally sell the resulting ebooks (as well as associated digital goods such as screencasts) on the [Softcover publishing platform](http://www.softcover.io/).

For more details about Softcover, see [*The Softcover Book*](http://manual.softcover.io/book).

## Installation

    $ gem install softcover

If installing on OS X Maverics or Later

    $ gem install softcover -- --with-cppflags=-I/usr/local/opt/openssl/include

## Usage

Run

    $ softcover help

for a list of supported commands.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Local Development

1. Check out the fork
2. Add new feature
3. Install it locally with `bundle exec rake install`

Once your changes are implemented, please update the documentation in the [Softcover manual](https://github.com/softcover/softcover_book) and make another pull request there.
