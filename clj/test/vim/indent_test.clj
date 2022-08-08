(ns vim.indent-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [clojure.java.io :as io]
            [vim.helpers :as h])
  (:import [java.io File]))

(defn get-test-cases [^File test-case-dir]
  (into []
        (comp
          (filter #(.isDirectory ^File %))
          (map #(.getName ^File %)))
        (.listFiles test-case-dir)))

(defn run-test-case [test-case-dir test-case]
  (testing (str "Preparation for " test-case)
    (let [input    (io/file test-case-dir test-case "in.clj")
          expected (io/file test-case-dir test-case "out.clj")
          actual   (File/createTempFile test-case ".clj")
          config   (let [f (io/file test-case-dir test-case "config.edn")]
                     (or (h/read-edn-file f) {}))
          cmds     (concat (:extra-cmds config)
                           (when (:indent? config true) ["normal! gg=G"])
                           ["write"])]
      (io/make-parents actual)
      (io/copy input actual)
      (h/vim! actual cmds :vimrc (io/file "vim/test-runtime.vim"))
      {:test-case     test-case
       :expected      (slurp expected)
       :expected-file expected
       :actual        (slurp actual)
       :actual-file   actual})))

;; TODO: do this parallisation more intelligently with agents.
(deftest test-indent
  "Runs all indentation tests in parallel"
  (let [test-case-dir (io/file (io/resource "indent-test-cases"))
        test-cases    (get-test-cases test-case-dir)]
    (doseq [{:keys [test-case expected expected-file actual actual-file]}
            (pmap (partial run-test-case test-case-dir) test-cases)]
      (testing test-case
        (is (= expected actual)
            (format "(not= \"%s\"\n      \"%s\")" expected-file actual-file))))))
