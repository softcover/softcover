# Softcover

[![Coverage Status](https://coveralls.io/repos/softcover/softcover/badge.svg)](https://coveralls.io/github/softcover/softcover)

Softcover is an ebook typesetting system for technical authors. This is the main gem, `softcover`, which depends on `polytexnic` to convert Markdown or PolyTeX input to HTML and LaTeX, and thence to EPUB, MOBI, and PDF. Authors can use Softcover to publish and optionally sell the resulting ebooks (as well as associated digital goods such as screencasts) on the [Softcover publishing platform](http://www.softcover.io/).

For more details about Softcover, see [*The Softcover Book*](http://manual.softcover.io/book).

## Installation

    $ gem install softcover

On some systems, you may need to add an extra option to handle SSL correctly:

    $ gem install softcover -- --with-cppflags=-I/usr/local/opt/openssl/include

Then install the dependencies as described [here](http://manual.softcover.io/book/getting_started#sec-installing_softcover).

## Usage

Run

    $ softcover help

for a list of supported commands.

## Adding a precompiled binary

We would like Softcover to support as many systems as possible. If you needed to compile your own `tralics` binary ([see here](https://github.com/softcover/tralics)) and would like to contribute it back to the project, please send an email to <michael@softcover.io> with the `tralics` binary attached and with the result of running the following command:

    $ ruby -e 'puts RUBY_PLATFORM'

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
