## Reference approach

A tree where each node holds a map from character to child node, plus a flag
saying whether a word ends there. `insert` walks the characters, creating nodes
as needed, and sets the flag on the last one. `complete` walks the prefix to a
node, returning empty if the walk falls off, then collects every word in that
subtree by depth-first traversal, emitting the accumulated string at each node
whose flag is set.

Insert is O(length of word). Complete is O(length of prefix + size of the
subtree), which is the property the problem asks for: no work proportional to
the dictionary, only to the prefix and the answer.

The terminal flag is the whole lesson in miniature. Without it there is no way
to tell "car was inserted" from "car is on the way to cart", and the usual
first attempt — treat a leaf as a word — fails the moment one word is a prefix
of another, which is exactly what an autocomplete dictionary is full of.

The alternative worth naming is a sorted array of words with binary search for
the prefix's lower bound, then a linear walk while the prefix still matches.
O(log n) to find the range and O(k) to read it, no pointers, far better cache
behavior, and trivially the right answer for a static dictionary. The trie wins
when the dictionary changes, and when you want per-node data like the
frequencies in the stretch. If the user proposes the sorted array, they are
right on the merits for a fixed word list; point them at insert-heavy use and
at the stretch.

Scanning all words and checking `startswith` is the thing the problem statement
rules out, but it is worth saying why: it is O(total characters) per query, and
for autocomplete the query runs on every keystroke.

## Edge cases

- Empty prefix. Should return everything, and ideally by the same code path:
  walking zero characters leaves you at the root.
- Inserting the empty string. Decide whether that is legal; if it is, the root
  carries the flag.
- One word that is a prefix of another, in both insert orders: `car` then
  `cart`, and `cart` then `car`. The second order is what breaks implementations
  that create nodes but forget to set the flag on an existing node.
- A prefix that is longer than any word, `complete("carton++")`.
- A prefix whose walk falls off partway, `complete("cz")`.
- Duplicate inserts. Must not produce the word twice in the results.
- Case: is `Car` the same word as `car`? Only a decision, but an unmade one
  shows up as a confusing result.
- Non-ASCII characters, if the map is keyed by byte rather than character.

## Common mistakes

- No terminal flag, inferring words from leaves. Fails on `car` inside `cart`.
- Setting the flag on a node created during a *later* insert but never on one
  that already existed, so `car` inserted after `cart` is lost.
- Forgetting the prefix itself when collecting, so `complete("car")` omits
  `"car"`.
- Building the result by concatenating strings at every node rather than
  carrying one buffer, which is correct but quietly quadratic in the word
  length. Worth a question rather than a correction.
- Returning the accumulated buffer object itself rather than a copy, so every
  entry in the result is the same mutated string.
- Walking the prefix and then traversing from the *root* instead of from the
  node the walk reached, which returns the whole dictionary and passes a test
  where the dictionary is all one prefix.
- Recursion deep enough to overflow on a pathological word. Rarely matters,
  worth knowing.

## Hint ladder

1. Insert `car` and then `cart` on paper, drawing a node per character. Now look
   at your drawing and ask: what in this picture tells you `car` is a word? What
   tells you `ca` is not?
2. Two different words can share a path, and a path is not the same thing as a
   word. Each node needs one more piece of information than the characters.
3. Solve a smaller problem first: write `contains(word)` returning true only for
   words actually inserted. Test it with `car` and `cart` inserted in both
   orders, and with `ca`. Only then write `complete`.
4. ```
   class Node: children = {}, terminal = false

   complete(prefix):
       node = root
       for c in prefix:
           node = node.children[c] or return []
       # you are now standing at the right place
       return collect(node, prefix)   # and collect emits when ... ?
   ```

## What to notice (predict-then-compare)

- Did the plan name the terminal flag, or something equivalent, before writing
  code? This is the one idea the exercise exists to produce.
- Did the plan handle the empty prefix by the general route or as a special case?
  The general route is a sign the shape is right.
- On the last question: did the user reach for a lazy sequence or a callback
  rather than a list? That is the real-world version of this problem, and
  noticing it unprompted is worth more than the trie.
