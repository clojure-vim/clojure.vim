# Clojure.vim

[Clojure][] syntax highlighting for Vim and Neovim, including:

- [Augmentable](#syntax-options) syntax highlighting.
- [Configurable](#indent-options) indentation.
- Basic insert-mode completion of special forms and public vars in
  `clojure.core`.  (Invoke with `<C-x><C-o>` or `<C-x><C-u>`.)


## Installation

These files are included in both Vim and Neovim.  However if you would like the
latest changes just install this repository like any other plugin.

Make sure that the following options are set in your vimrc so that all features
are enabled:

```vim
syntax on
filetype plugin indent on
```


## Configuration

### Folding

Setting `g:clojure_fold` to `1` will enable the folding of Clojure code.  Any
list, vector or map that extends over more than one line can be folded using
the standard Vim fold commands.

(Note that this option will not work with scripts that redefine the bracket
regions, such as rainbow parenphesis plugins.)


### Syntax options

#### `g:clojure_syntax_keywords`

Syntax highlighting of public vars in `clojure.core` is provided by default,
but additional symbols can be highlighted by adding them to the
`g:clojure_syntax_keywords` variable.

```vim
let g:clojure_syntax_keywords = {
    \   'clojureMacro': ["defproject", "defcustom"],
    \   'clojureFunc': ["string/join", "string/replace"]
    \ }
```

(See `s:clojure_syntax_keywords` in the [syntax script](syntax/clojure.vim) for
a complete example.)

There is also a buffer-local variant of this variable (`b:clojure_syntax_keywords`)
that is intended for use by plugin authors to highlight symbols dynamically.

By setting `b:clojure_syntax_without_core_keywords`, vars from `clojure.core`
will not be highlighted by default.  This is useful for namespaces that have
set `(:refer-clojure :only [])`.


#### `g:clojure_discard_macro`

Set this variable to `1` to enable highlighting of the
"[discard reader macro](https://clojure.org/guides/weird_characters#_discard)".
Due to current limitations in Vim's syntax rules, this option won't highlight
stacked discard macros (e.g. `#_#_`).  This inconsitency is why this option is
disabled by default.


### Indent options

By default Clojure.vim will attempt to follow the indentation rules in the
[Clojure Style Guide](https://guide.clojure.style), but various configuration
options are provided to alter the indentation as you prefer.

> **Warning**<br>
> If your installation of Vim does not include `searchpairpos()`, the indent
> script falls back to normal `'lisp'` and `'lispwords'` indenting, ignoring
> the following indentation options.


#### `clojure_indent_rules`

> **Note**<br>
> The indentation code was recently rebuilt, which included the removal of
> several former configuration options (`clojure_fuzzy_indent`,
> `clojure_fuzzy_indent_patterns`, `clojure_fuzzy_indent_blacklist`,
> `clojure_special_indent_words`, `clojure_cljfmt_compat` and now ignores the
> value of `'lispwords'`).
>
> All of those options were rolled into this new option.


#### `clojure_align_multiline_strings`

Alter alignment of newly created lines within multi-line strings (and regular
expressions).

```clojure
;; let g:clojure_align_multiline_strings = 0  " Default
(def default
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua.")

;; let g:clojure_align_multiline_strings = 1
(def aligned
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
   eiusmod tempor incididunt ut labore et dolore magna aliqua.")

;; let g:clojure_align_multiline_strings = -1
(def traditional
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua.")
```

There is also a buffer-local (`b:`) version of this option.

> **Note**<br>
> Indenting the string with `=` will not alter the indentation of existing
> multi-line strings as that would break intentional formatting.


#### `clojure_align_subforms`

By default, parenthesized compound forms that look like function calls and
whose head subform is on its own line have subsequent subforms indented by
two spaces relative to the opening paren:

```clojure
(foo
  bar
  baz)
```

Setting this option to `1` changes this behaviour so that all subforms are
aligned to the same column, emulating the default behaviour of
[clojure-mode.el](https://github.com/clojure-emacs/clojure-mode):

```clojure
(foo
 bar
 baz)
```


## Contribute

Pull requests are welcome!  Make sure to read the
[`CONTRIBUTING.md`](CONTRIBUTING.md) for useful information.


## Acknowledgements

[Clojure.vim][] is a continuation of [vim-clojure-static][].
_Vim-clojure-static_ was created by [Sung Pae](https://github.com/guns).  The
original copies of the packaged runtime files came from
[Meikel Brandmeyer](http://kotka.de/)'s [VimClojure][] project with permission.

Thanks to [Tim Pope](https://github.com/tpope/) for advice in
[#vim](https://www.vi-improved.org/).


## License

Clojure.vim is licensed under the [Vim
License](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) for
distribution with Vim.

- Copyright © 2020–2021, The clojure-vim contributors.
- Copyright © 2013–2018, Sung Pae.
- Copyright © 2008–2012, Meikel Brandmeyer.
- Copyright © 2007–2008, Toralf Wittner.

See [LICENSE](https://github.com/clojure-vim/clojure.vim/blob/master/LICENSE)
for more details.


<!-- Links -->

[clojure.vim]: https://github.com/clojure-vim/clojure.vim
[vim-clojure-static]: https://github.com/guns/vim-clojure-static
[vimclojure]: https://www.vim.org/scripts/script.php?script_id=2501
[clojure]: https://clojure.org

<!-- vim: set tw=79 : -->
