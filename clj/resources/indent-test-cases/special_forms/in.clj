(try (/ 1 0)
  (catch Exception e
    (foo)))

(try
     (/ 1 0)
     (catch Exception e
       (foo)))
