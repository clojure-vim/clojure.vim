(defproject vim-clojure-static "0.1.0"
  :description  "Utilities and tests for Vim's Clojure runtime files."
  :url          "https://github.com/clojure-vim/clojure.vim"
  :license      {:name     "Vim License"
                 :url      "http://vimdoc.sourceforge.net/htmldoc/uganda.html#license"
                 :comments ":help license"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/data.csv "1.0.1"]
                 [frak "0.1.9"]]
  :profiles {:test {:managed-dependencies [[org.clojure/tools.cli "1.0.219"]
                                           [org.clojure/tools.reader "1.3.6"]]
                    :dependencies [[lambdaisland/kaocha "1.85.1342"]]}}
  :aliases  {"test" ["with-profile" "+test" "run" "-m" "kaocha.runner"]})
