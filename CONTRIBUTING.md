# Contributing

A large portion of the syntax file is generated using Clojure code in the
`clj/` directory.  Generation of Vim code in this fashion is preferred over
hand crafting of the same.

There is an incomplete syntax test suite in `clj/test/`.  Any additions and
improvements to these tests are highly appreciated.

To contribute to Clojure.vim you will need [Leiningen][].


## Update syntax files

When a new Clojure version is released, perform the following steps to update
the syntax files to add syntax highlighting for new functions, macros and
special forms.

```
$ cd clj/
$ lein repl
> (load-file "src/vim_clojure_static/generate.clj")
> (ns vim-clojure-static.generate)
> (update-project! "..")
```

### Update Unicode syntax

Update the file used to generate the Unicode character classes highlighted in Clojure
regex strings.

```sh
cd clj/
./bin/update-unicode
```

Then update the syntax files using the steps in the previous section.


## Run tests

Run the test suite using this command:

```
lein test
```


## Submit latest changes to upstream Vim

_WIP_


[Leiningen]: https://leiningen.org/#install
