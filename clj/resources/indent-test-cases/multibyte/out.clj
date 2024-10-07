(let [Δt (if foo
           bar
           baz)])

(let [Δt {:foo 'foo
          :bar
          123}])

(let [Δt '[if foo
           bar
           baz]])

(let [Δt (assoc foo
                :bar
                123)])
