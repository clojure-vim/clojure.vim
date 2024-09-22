(def DateTime #?(:clj org.joda.time.DateTime,
                 :cljs goog.date.UtcDateTime))

#?(:clj
   (defn regexp?
     "Returns true if x is a Java regular expression pattern."
     [x]
     (instance? java.util.regex.Pattern x)))

#?@(:clj  [5 6 7 8]
    :cljs [1 2 3 4])
