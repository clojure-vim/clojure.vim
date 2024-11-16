(defrecord Thing [a]
  FileNameMap
  (getContentTypeFor [_ file-name]
    (str a "-" file-name))
  Object
  (toString [_]
    "My very own thing!!"))

(defrecord TheNameOfTheRecord
           [a pretty long argument list]
  SomeType
  (assoc [_ x]
    (.assoc pretty x 10)))

(extend-protocol MyProtocol
  goog.date.Date
  (-to-date-time [x]
    (goog.date.UtcDateTime. (.getYear x)
                            (.getMonth x)
                            (.getDate x))))
