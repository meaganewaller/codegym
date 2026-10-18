## Reference approach

This is longest common subsequence, and the diff is its complement. Build a
table `L[i][j]` = length of the LCS of `a[i..]` and `b[j..]`: if `a[i] == b[j]`
then `1 + L[i+1][j+1]`, else `max(L[i+1][j], L[i][j+1])`. Then walk from
`(0, 0)`: equal lines are a keep and move both cursors; otherwise move in the
direction the table says is better, emitting a delete or an insert.

O(n * m) time and memory. For the fewest edits, note that keeps + deletes = len(a)
and keeps + inserts = len(b), so maximizing keeps is exactly minimizing edits —
that equivalence is the insight the first two questions are built to produce.

Two refinements worth naming:

**Hirschberg** gets memory to O(min(n, m)) by divide and conquer, recomputing
rather than storing. Same time complexity.

**Myers' algorithm**, which is what git and `diff` actually use, runs in
O((n + m) * d) where `d` is the number of edits. On the 10,000-identical-lines
question that is the difference between 100 million table cells and a few
thousand steps, because it searches by edit distance rather than by position.
A user who realizes their table is quadratic *regardless* of how similar the
files are has found the thing that question is pointing at, and that is a better
outcome than implementing Myers in 45 minutes.

Nearly every real implementation also strips the common prefix and suffix first,
which is five lines and makes the common case enormously faster without changing
the algorithm. Worth suggesting if the user finishes early.

## Edge cases

- Both lists empty: empty output.
- One empty: all deletes, or all inserts.
- Identical lists: all keeps, no edits.
- Completely disjoint lists. The expected output is all deletes then all
  inserts, or interleaved — both are minimal, which is a good moment to notice
  the answer is not unique.
- Repeated lines, which is where diff gets genuinely interesting: `["a","a","b"]`
  to `["a","b"]` has two different minimal answers depending on which `a` you
  keep.
- A one-line change, `["x"]` to `["y"]`, which must not come out as insert-then-
  delete-everything.
- Lines that differ only in trailing whitespace. A decision, not a bug.
- Very long identical files, which is the performance case.

## Common mistakes

- A greedy walk that takes a match whenever it sees one. Fails on
  `["a","b","c"]` to `["b","a"]`-shaped inputs, and the failure is subtle enough
  that small tests pass.
- Off-by-one in the table, especially mixing up whether `L[i][j]` means "from
  here on" or "up to here". Both conventions work; mixing them inside one
  function does not.
- Walking the table from the wrong corner, or in the wrong direction, producing
  a reversed diff.
- Breaking the tie in the `max` inconsistently between the table build and the
  walk, so the walk leaves the optimal path and the output is correct but not
  minimal.
- Returning only the LCS rather than the operations. The LCS is the keeps; the
  deletes and inserts still have to be emitted in the right positions.
- Comparing lines by identity rather than by value, which works in a test where
  both lists are literals.
- Recursion without memoization, which is exponential and will appear to hang on
  a 50-line file. A good moment to ask the user to predict the running time
  before they run it.

## Hint ladder

1. Count the deletions and insertions in the expected output for the first
   example, then count them in the delete-everything-insert-everything version.
   Now count the lines that were *kept* in each. What relationship do you see
   between those two numbers?
2. Minimizing edits and maximizing kept lines are the same problem. Kept lines
   appear in both files, in the same relative order, though not necessarily
   adjacently. That has a name.
3. Solve a smaller problem first: forget the diff and write only the *length* of
   the longest common subsequence of two lists. Test it on `["a","b","c"]` and
   `["a","c"]` (answer 2) and on disjoint lists (answer 0). Only then work out
   how to recover the operations.
4. ```
   L[i][j] = length of LCS of a[i..] and b[j..]

   if a[i] == b[j]:  L[i][j] = 1 + L[i+1][j+1]
   else:             L[i][j] = max( L[i+1][j], L[i][j+1] )

   # then walk from (0,0): equal -> keep, else go the way the table prefers.
   # Which operation does moving i mean? Which does moving j mean?
   ```

## What to notice (predict-then-compare)

- Did the plan find the keeps-versus-edits equivalence, or try to minimize edits
  directly? Going at the edits directly usually produces a greedy walk.
- Did the plan say what a table cell *means* in one sentence? The off-by-one
  bugs here are almost always an unstated or drifting definition.
- Did the plan notice the answer is not unique on repeated lines? Any test
  asserting one exact output will be fragile, and realizing that before writing
  the tests is worth more than the algorithm.
- On the 10,000-line question: did the user see that their approach pays the same
  quadratic cost whether the files differ by one line or entirely? That is the
  gap between a textbook diff and a usable one.
