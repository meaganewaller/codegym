## Reference approach

A hash map from key to node, plus a doubly linked list of nodes ordered by
recency with most-recent at the head. `get` looks the key up in the map, unlinks
its node, pushes it to the head, returns the value. `put` does the same when the
key exists; when it does not, it creates a node at the head, stores it in the
map, and if the size now exceeds capacity removes the tail node and deletes its
key from the map.

Both operations are O(1), and the memory is O(capacity). The doubly linked list
is what makes it O(1): you have to unlink a node found by key without walking,
which needs a pointer to its predecessor, which a singly linked list cannot give
you in constant time.

The alternative, in languages that have one, is an insertion-ordered dictionary
with a move-to-end operation: Python's `OrderedDict` with `move_to_end`, Java's
`LinkedHashMap` with `accessOrder` set, or Ruby's `Hash`, which preserves
insertion order, where `delete` then re-insert moves a key to the end. Three
lines instead of thirty and the right answer in production. The trade-off is
that it hides the exact mechanism this exercise is about, and the moment the
requirement shifts to LFU or a TTL it stops being free. If the user reaches for
it, that is good engineering judgment: ask them to describe what the library is
doing underneath, then have them do the stretch, where the shortcut runs out.

A sorted structure keyed on a timestamp or counter is a common first instinct.
It works and gives O(log n), and the useful question is what it buys for the
extra cost: nothing here, since recency order only ever changes at one end.

## Edge cases

- Capacity 0. Every `put` is a no-op and every `get` misses. Many solutions
  evict the node they just inserted, or crash removing from an empty list.
- Capacity 1. Exposes eviction code that assumes head and tail are different
  nodes.
- Overwriting an existing key at full capacity. Must not evict, because the size
  does not grow. A solution that checks capacity before checking whether the key
  exists gets this wrong.
- `get` on a missing key, and on an empty cache.
- Storing a legitimately falsy value: `nil`, `false`, `0`, `""`. If a miss is
  signalled by returning nil, these become indistinguishable from a miss. Worth
  raising even if the user's language makes it awkward.
- Re-putting the same key repeatedly: the list must not grow a node each time.
- A key used, then every other key used, then evicted. The full cycle.

## Common mistakes

- A singly linked list, discovered only when unlinking a middle node needs its
  predecessor. This is the moment the exercise is built around; let them reach it.
- Evicting from the wrong end. Symptom: the most recently used key disappears
  and the stale one survives.
- Updating the list but not the map on eviction, which leaks keys and makes the
  map grow without bound. The cache looks right until it is memory profiled.
- Treating `put` of an existing key as insert-plus-evict rather than
  update-plus-promote, which can evict a live entry and leave size below capacity.
- Forgetting to promote on `get`, which quietly turns it into a FIFO cache. It
  passes any test that never re-reads a key before eviction, which is why the
  worked example above does exactly that.
- Head and tail handling without sentinel nodes. Not wrong, but most of the bugs
  in a hand-rolled version are nil checks at the ends; sentinels make them vanish.

## Hint ladder

1. Walk the worked example by hand and write down, after each operation, the
   order of keys from most to least recently used. What operation are you
   performing on that order each time?
2. You have two requirements that pull in different directions: find any key
   immediately, and know which key is oldest immediately. One data structure is
   not going to do both. What happens if you use two, pointing at the same
   entries?
3. Solve a smaller problem first: given a list of nodes and a reference to one
   node in the middle, remove it from the list in constant time. What does each
   node need to hold for that to be possible? Build and test just that.
4. ```
   class Node: key, value, prev, next

   map  = {}                 # key -> node
   head = sentinel; tail = sentinel; head.next = tail; tail.prev = head

   get(key):
       node = map[key] or return miss
       unlink(node); push_front(node)
       return node.value

   put(key, value):
       if key in map:
           # two things happen here, and eviction is not one of them
       else:
           # insert, then check one condition, and update TWO structures
   ```

## What to notice (predict-then-compare)

- Did the plan answer the two specification questions, or go straight to
  structures? The overwrite-at-capacity bug is a direct consequence of skipping
  them, and it is the most common failure here.
- Did the plan name two structures and say what each one is for? A plan with one
  structure is a plan that will be rewritten halfway through.
- Did the plan say what must be updated on eviction, and did it count both the
  list and the map? Compare that count to the finished code.
- If the user chose a library ordered dictionary: did they say what it does
  underneath? If yes, they skipped the exercise correctly rather than by accident.
