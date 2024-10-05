# Clojure.vim

**Configurable [Clojure][] syntax highlighting, indentation (and more) for Vim and Neovim!**

> [!TIP]
> This plugin comes packaged with Vim and Neovim.  However if you would like to
> always use the latest version, you can install this plugin like you would any
> other.

Make sure your vimrc contains the following options to enable all features:

```vim
syntax on
filetype plugin indent on
```


## Syntax highlighting

### `g:clojure_syntax_keywords`

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


### `g:clojure_discard_macro`

Set this variable to `1` to enable highlighting of the
"[discard reader macro](https://clojure.org/guides/weird_characters#_discard)".
Due to current limitations in Vim's syntax rules, this option won't highlight
stacked discard macros (e.g. `#_#_`).  This inconsistency is why this option is
disabled by default.


## Indentation

Clojure indentation differs somewhat from traditional Lisps, due in part to the
use of square and curly brackets, and otherwise by community convention.  As
these conventions are not universally followed, the Clojure indent script
offers ways to adjust the indentation.

> [!WARNING]
> The indentation code has recently been rebuilt which included the
> removal/replacement of the following configuration options:
>
> | Config option                     | Replacement (if any)               |
> |-----------------------------------|------------------------------------|
> | `clojure_maxlines`                |                                    |
> | `clojure_cljfmt_compat`           | `clojure_indent_style`             |
> | `clojure_align_subforms`          | `clojure_indent_style`             |
> | `clojure_align_multiline_strings` | `clojure_indent_multiline_strings` |
> | `clojure_fuzzy_indent`            |                                    |
> | `clojure_fuzzy_indent_blacklist`  |                                    |
> | `clojure_special_indent_words`    | `clojure_indent_rules`             |
> | `'lispwords'`                     | `clojure_indent_rules`             |


### Indentation style

The `clojure_indent_style` config option controls the general indentation style
to use.  Choose from several common presets:

| Value | Default | Description |
|-------|---------|-------------|
| `standard` | ✅ | Conventional Clojure indentation.  ([_Clojure Style Guide_](https://guide.clojure.style/).) |
| `traditional` | | Indent like traditional Lisps.  (Earlier versions of Clojure.vim indented like this.) |
| `uniform`     | | Indent uniformly to 2 spaces with no alignment (a.k.a. [_Tonsky_ indentation](https://tonsky.me/blog/clojurefmt/)). |

```vim
let g:clojure_indent_style = 'uniform'      " Set the default...
let b:clojure_indent_style = 'traditional'  " ...or override it per-buffer.
```


### Indentation rules

> [!NOTE]
> These options are ignored if an indentation style of "uniform" is selected.

`clojure_indent_rules` & `clojure_fuzzy_indent_patterns`


### Multi-line strings

Control alignment of _new_ lines within Clojure multi-line strings and regular
expressions with `clojure_indent_multiline_strings`.

> [!NOTE]
> Indenting with `=` will not alter the indentation within multi-line strings,
> as this could break intentional formatting.

Pick from the following multi-line string indent styles:

| Value | Default | Description |
|-------|---------|-------------|
| `standard` | ✅ | Align to the _front_ of the `"` or `#"` delimiter.  Ideal for doc-strings. |
| `pretty`      | | Align to the _back_ of the `"` or `#"` delimiter. |
| `traditional` | | No indent: align to left edge of file. |

```vim
let g:clojure_indent_multiline_strings = 'pretty'       " Set the default...
let b:clojure_indent_multiline_strings = 'traditional'  " ...or override it per-buffer.
```


## Code folding

Setting `g:clojure_fold` to `1` will enable the folding of Clojure code.  Any
list, vector or map that extends over more than one line can be folded using
the standard Vim fold commands.

(Note that this option will not work with scripts that redefine the bracket
regions, such as rainbow parenthesis plugins.)


## Insert-mode completion

Very basic insert-mode completion of special forms and public vars from
`clojure.core` is included in Clojure.vim.  Invoke it with `<C-x><C-o>` or
`<C-x><C-u>`.


## Contribute

Pull requests are welcome!  Make sure to read the
[`CONTRIBUTING.md`](CONTRIBUTING.md) for useful information.


## Acknowledgements

[Clojure.vim][] is a continuation of [vim-clojure-static][].
_Vim-clojure-static_ was created by [Sung Pae](https://github.com/guns).  The
original copies of the packaged runtime files came from
[Meikel Brandmeyer](http://kotka.de/)'s [VimClojure][] project with permission.
Thanks to [Tim Pope](https://github.com/tpope/) for advice in `#vim` on IRC.


## License

Clojure.vim is licensed under the [Vim License](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license)
for distribution with Vim.

- Copyright © 2020–2024, The clojure-vim contributors.
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
