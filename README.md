# Install Polytexnic CLI for **Development**
- RVM users: 'rvm @global' or 'rvm <ruby-ver>@global'
  - CLI depends on where bundle installs to
- bundle install
- rake install

- test by opening a iterm tab, then run 'polytexnic'
- setup to point to localhost
  - polytexnic config host='http://localhost:3000'

- ensure polytexnic-app setup with S3 credentials
  - see that project's README
- should now be able to `polytexnic login` with an email/password from the
  localhost polytexnic app
  - in a folder with html files, should be able to `polytexnic publish` to
    create a book w/chapter objects on the server, upload assets to S3 and link
    the Rails objects with their S3 locations


# Polytexnic CLI

Command line interface for Polytexnic.com

## Installation

    $ gem install polytexnic

## Usage

    $ polytexnic <command>

## Commands:

* login
* logout
* build:html, build:pdf, build:epub, build:mobi, build:all
* build (aliased to build:html)
* publish
* new

## Development Notes
    $ polytexnic config:add host=http://localhost:3000

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
