(let [x (fn [y] 1)]
  (->> "ola"
       (x)))

(letfn [(x [y] 1)]
  (->> "ola"
       (x)))

(->> "ola"
     (x))

(defn foo []
  (letfn [(x [y] 1)]
    (->> "ola"
         (x))))

(letfn [(twice [x]
          (* x 2))
        (six-times [y]
          (* (twice y) 3))]
  (println "Twice 15 =" (twice 15))
  (println "Six times 15 =" (six-times 15)))

(letfn [(twice [x]
          (* x 2))]
  (->> "ola"
       (x)))

(letfn [(foo [x y]
          (->> x
               y
               :bar))
        (twice [x]
          (* x 2))
        (six-times [y]
          (* (twice y) 3))]
  (foo #{:foo :bar :biz} :foo))
