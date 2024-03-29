(def DateTime #?(:clj org.joda.time.DateTime,
                      :cljs goog.date.UtcDateTime))

#?(:cljs
    (extend-protocol ToDateTime
      goog.date.Date
      (-to-date-time [x]
        (goog.date.UtcDateTime. (.getYear x) (.getMonth x) (.getDate x)))))

#?@(:clj  [5 6 7 8]
      :cljs [1 2 3 4])))
