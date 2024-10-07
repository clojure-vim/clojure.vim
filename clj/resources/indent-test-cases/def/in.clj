(defn- insert!
  ^Map [^Map ^String k ^Object v]
  (if (.putIfAbsent m k v)
    (recur m (str \@ k) v)
    m))
