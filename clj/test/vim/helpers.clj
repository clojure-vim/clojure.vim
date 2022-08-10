(ns vim.helpers
  (:require [clojure.edn :as edn]
            [clojure.java.shell :as shell])
  (:import [java.io File FileReader PushbackReader]))

(defn read-edn-file [^File file]
  (when (.exists file)
    (with-open [rdr (FileReader. file)]
      (edn/read (PushbackReader. rdr)))))

(def ^:dynamic *vim* "vim")

(defn vim!
  "Run commands on a file in Vim."
  [^File file cmds & {:keys [vimrc], :or {vimrc "NONE"}}]
  (let [cmds (mapcat (fn [cmd] ["-c" cmd]) cmds)
        args (concat ["--clean" "-N" "-u" (str vimrc)] cmds ["-c" "quitall!" "--" (str file)])
        ret  (apply shell/sh *vim* args)]
    (when (pos? (:exit ret))
      (throw (ex-info "Failed to run Vim command"
                      (assoc ret :vim *vim*, :args args))))))
