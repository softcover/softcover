# A chapter {#cha:a_chapter}

This is the first paragraph of the PolyTeXnic Markdown template. It shows how to write a document in Markdown, a lightweight markup language. This is actually a little lie, because Markdown isn't really powerful enough to make longer documents, and in fact PolyTeXnic's Markdown support is built on top of the [kramdown](http://kramdown.rubyforge.org/) project. Even then, it's still not all that powerful, and authors who want more control should use the alternate *PolyTeX* input format, which is a subset of the LaTeX typesetting language optimized for ebooks. For more information, see *The PolyTeXnic Book*, available online at <http://polytexnic.org/book>. To learn how to easily publish (and optionally sell) documents produced with PolyTeXnic, visit [Softcover.io](http://softcover.io/).

This is the *second* paragraph, showing how to emphasize text.[^sample_footnote] You can also make text **bold** or *italicized* (which looks the same as emphasized text).

*Note*: "PolyTeXnic" is pronounced exactly like the English word *polytechnic*.[^polytexnic_origin]

## A section {#sec:a_section}

This is a section.

### Source code {#sec:source_code}

This is a subsection.

PolyTeXnic comes with full support for syntax-highlighted source code using kramdown's default syntax:

{lang="ruby"}
    def hello
      puts "hello, world"
    end

PolyTeXnic's Markdown mode also extends kramdown to support GitHub-flavored Markdown's "code fencing":

```ruby
def hello
  puts "hello, world!"
end
```

Authors who want numbered *code listings* (linked cross-references) should use the PolyTeX input format.

### Mathematics {#sec:mathematics}

PolyTeXnic's Markdown mode supports limited mathematical typesetting, including inline math, such as
{$$}\phi^2 - \phi - 1 = 0{/$$}, and centered math, such as

{$$}\phi = \frac{1+\sqrt{5}}{2}.{/$$}

Authors desring more extensive math support (including pure LaTeX syntax, numbered equations, and cross-referencing) should use the PolyTeX input format.


## Images and tables

This is the second section.

PolyTeXnic supports the inclusion of images, like this

![image](images/2011_michael_hartl.png)

### Tables

 supports raw tables via the environment. To make a tabular environment
into a full-blown table, with a number and a caption, use the
environment (Table [table:rails~a~ctions]), which includes some special
magic to make the font size nicer in PDFs.

|**HTTP request** | **URL** & **Action** & **Purpose** |

| `GET` | /users | `index` | page to list all users |
| `GET` | /users/1 | `show` | page to show user with id `1` |
| `GET` | /users/new | `new` | page to make a new user |
| `POST` | /users | `create` | create a new user |
| `GET` | /users/1/edit | `edit` | page to edit user with id `1` |
| `PATCH` | /users/1 | `update` | update user with id `1` |
| `DELETE` | /users/1 | `destroy` | delete user with id `1`


|Verb   |Action                                          |Idempotent?|
|-------|------------------------------------------------|-----------|
|GET    |Responds with information about the resource    |Yes        |
|POST   |Creates a sub-resource of the resource POSTed to|No         |
|PUT    |Creates or updates the resource being PUT to    |Yes        |
|DELETE |DELETES the resource                            |Yes        |
|HEAD   |Gets metadata about the resource                |Yes        |


## Command-line interface

PolyTeXnic comes with a command-line interface called `poly`. To get more information, just run `poly help`:

```console
$ poly help
Commands:
  poly build, build:all           # Build all formats
  poly build:epub                 # Build EPUB
  poly build:html                 # Build HTML
  poly build:mobi                 # Build MOBI
  poly build:pdf                  # Build PDF
  poly build:preview              # Build book preview in all formats
  poly config                     # View local config
  poly config:add key=value       # Add to your local config vars
  poly epub:validate, epub:check  # Validate EPUB with epubcheck
  poly help [COMMAND]             # Describe available commands...
  poly login                      # Log into Softcover account
  poly logout                     # Log out of Softcover account
  poly new <name>                 # Generate new book directory structure.
  poly open                       # Open book on Softcover website (OS X only)
  poly publish                    # Publish your book on Softcover
  poly publish:screencasts        # Publish screencasts
  poly server                     # Run local server
```

For additional help on a given command, run `poly help <command>`:

```console
$ poly help build
Usage:
  poly build, build:all

Options:
  -q, [--quiet]   # Quiet output
  -s, [--silent]  # Silent output

Build all formats
```

Miscellanea
-----------

Apart from two mostly empty chapters, this is the end of the template. In fact, let’s include the last chapter in its entirety, just to see how mostly empty it is:

<<(chapters/yet_another_chapter.md)

Visit <http://polytexnic.org/book> to learn more about what  can do.


[^sample_footnote]: This is a footnote. It is numbered automatically.

[^polytexnic_origin]: PolyTeXnic is build on LaTeX (pronounced *lay*-tech), which in turn is build on legendary computer scientist Donald Knuth's TeX typesetting system.
