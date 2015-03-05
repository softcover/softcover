# Title of the Article

The is the first paragraph of the Softcover document template. It shows how to write a document in [Markdown](http://daringfireball.net/projects/markdown/), augmented with some custom extensions, including numbered footnotes[^sample-footnote] and embedded \LaTeX.[^pronunciation]

This is the second paragraph, showing how to *emphasize* text. You can also make text **bold**.

## A section
\label{sec:a_section}

This is a section. We'll take a look at some of the features supported by Softcover.

### Source code

In plain Markdown, you can typeset code samples and other verbatim text using four spaces of indentation:

    def hello
      puts "hello, world"
    end

Softcover also supports GitHub-style "code fencing" with language-specific syntax highlighting:

```ruby
def hello
  puts "hello, world!"
end
```

The second of these can be combined with Softcover's `codelisting` environment to make code listings via embedded \LaTeX, as shown in Listing~\ref{code:hello}.

\begin{codelisting}
\codecaption{Hello, world.}
\label{code:hello}
```ruby
def hello
  puts "hello, world!"
end
```
\end{codelisting}


### Mathematics

Softcover supports mathematical typesetting via embedded \LaTeX. This includes both inline math, such as \( \phi^2 - \phi - 1 = 0, \) and centered math, such as
\[ \phi^2 - \phi - 1 = 0. \]

Softcover also supports numbered equations via embedded \LaTeX, as seen in Eq.~\eqref{eq:phi} and Eq.~\eqref{eq:gauss}.

\begin{equation}
\label{eq:phi}
\phi = \frac{1+\sqrt{5}}{2} \approx 1.618
\end{equation}

\begin{equation}
\label{eq:gauss}
\mathbf{\nabla}\cdot\mathbf{B} = 0 \qquad\mbox{Gauss's law}
\end{equation}


## Images and tables
\label{sec:images_and_tables}

This is the second section. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

### Images

Softcover supports the inclusion of images, like this:

![Some dude.](images/01_michael_hartl_headshot.jpg)

Using \LaTeX\ labels, you can also include a caption (as in Figure~\ref{fig:captioned_image}) or just a figure number (as in Figure~\ref{fig:figure_number}).

![Some dude.\label{fig:captioned_image}](images/01_michael_hartl_headshot.jpg)

![\label{fig:figure_number}](images/01_michael_hartl_headshot.jpg)

### Tables

Softcover supports raw tables via a simple table syntax:

|**HTTP request** | **URL** | **Action** | **Purpose** |
| `GET` | /users | `index` | page to list all users |
| `GET` | /users/1 | `show` | page to show user with id `1` |
| `GET` | /users/new | `new` | page to make a new user |
| `POST` | /users | `create` | create a new user |
| `GET` | /users/1/edit | `edit` | page to edit user with id `1` |
| `PATCH` | /users/1 | `update` | update user with id `1` |
| `DELETE` | /users/1 | `destroy` | delete user with id `1` |


## Final section

This is the final section. The previous sections were Section~\ref{sec:a_section} and Section~\ref{sec:images_and_tables}.

[^sample-footnote]: Like this.

[^pronunciation]: Pronunciations of "LaTeX" differ, but *lay*-tech is the one I prefer.
