(with-open [f (io/file)]
           (slurp f))

(with-meta obj
  {:foo 1})

(with-meta
  obj
  {:foo 1})

(with-out-str
())

(with-in-str
      ())
