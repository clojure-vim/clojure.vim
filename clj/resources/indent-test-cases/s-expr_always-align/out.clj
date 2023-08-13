(assoc {:foo 1}
       :bar [2
             3
             4]
       :biz 5)

[:foo :bar
 :biz :baz
 "asdf"
 'a345r
 1234]

{:hello "world"
 :example "test"
 1234 'cake
 [qwer
  asdf
  zxcv]  #{1 2
           3 4 :bar}}

(qwer
 [12
  34
  56]
 xczv)

((constantly +)
 1
 2)

((constantly +) 1
                2)

(filter
 #(= 0 (mod %
            2))
 (range 1 10))

(#(foo)
 bar)

(#(foo
   bar))

(#(foo bar
       a))

(#(foo bar)
 a)

(#(foo bar) a
            b)

#_(:foo
   {:foo 1})

(#_(foo)
 bar)

(#_(foo
    bar))

(#_(foo bar)
 a)

(@foo bar
      biz)

(@foo
 bar
 biz)

(#'foo bar
       biz)

(#'foo
 bar
 biz)

('foo bar
      biz)

('foo
 bar
 biz)
