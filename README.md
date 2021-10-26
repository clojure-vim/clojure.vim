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

Clojure indentation differs somewhat from traditional Lisps, due in part to
the use of square and curly brackets, and otherwise by community convention.
These conventions are not universally followed, so the Clojure indent script
offers a few configuration options.

(If the current Vim does not include `searchpairpos()`, the indent script falls
back to normal `'lisp'` indenting, and the following options are ignored.)


#### `g:clojure_maxlines`

Sets maximum scan distance of `searchpairpos()`.  Larger values trade
performance for correctness when dealing with very long forms.  A value of
0 will scan without limits.  The default is 300.


#### `g:clojure_fuzzy_indent`, `g:clojure_fuzzy_indent_patterns`, `g:clojure_fuzzy_indent_blacklist`

The `'lispwords'` option is a list of comma-separated words that mark special
forms whose subforms should be indented with two spaces.

For example:

```clojure
(defn bad []
      "Incorrect indentation")

(defn good []
  "Correct indentation")
```

If you would like to specify `'lispwords'` with a pattern instead, you can use
the fuzzy indent feature:

```vim
" Default
let g:clojure_fuzzy_indent = 1
let g:clojure_fuzzy_indent_patterns = ['^with', '^def', '^let']
let g:clojure_fuzzy_indent_blacklist = ['-fn$', '\v^with-%(meta|out-str|loading-context)$']
```

`g:clojure_fuzzy_indent_patterns` and `g:clojure_fuzzy_indent_blacklist` are
lists of patterns that will be matched against the unqualified symbol at the
head of a list.  This means that a pattern like `"^foo"` will match all these
candidates: `foobar`, `my.ns/foobar`, and `#'foobar`.

Each candidate word is tested for special treatment in this order:

1. Return true if word is literally in `'lispwords'`
2. Return false if word matches a pattern in `g:clojure_fuzzy_indent_blacklist`
3. Return true if word matches a pattern in `g:clojure_fuzzy_indent_patterns`
4. Return false and indent normally otherwise


#### `g:clojure_special_indent_words`

Some forms in Clojure are indented such that every subform is indented by only
two spaces, regardless of `'lispwords'`.  If you have a custom construct that
should be indented in this idiosyncratic fashion, you can add your symbols to
the default list below.

```vim
" Default
let g:clojure_special_indent_words = 'deftype,defrecord,reify,proxy,extend-type,extend-protocol,letfn'
```


#### `g:clojure_align_multiline_strings`

Align subsequent lines in multi-line strings to the column after the opening
quote, instead of the same column.

For example:

```clojure
(def default
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
  enim ad minim veniam, quis nostrud exercitation ullamco laboris
  nisi ut aliquip ex ea commodo consequat.")

(def aligned
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
   eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
   enim ad minim veniam, quis nostrud exercitation ullamco laboris
   nisi ut aliquip ex ea commodo consequat.")
```


#### `g:clojure_align_subforms`

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
