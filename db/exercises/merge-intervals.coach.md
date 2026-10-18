## Reference approach

Sort by `start`, then fold left. Keep the last interval of the result; for each
next interval, if its `start` is within the kept interval's reach, extend that
interval's `end` to the larger of the two ends, otherwise push it as a new
interval.

Sorting dominates: O(n log n) time, O(n) for the result, or O(1) extra if you
merge in place after sorting.

The alternative is a sweep over boundary events: emit `(start, +1)` and
`(end, -1)`, sort the events, and walk them keeping a running depth, closing an
interval each time depth returns to zero. Same asymptotic cost and more moving
parts for this problem, but it generalizes to questions this fold cannot answer,
such as "how many intervals cover this point" or "where do at least three
overlap". Worth naming if the user is heading somewhere more general.

A user who tries to avoid sorting is not wrong to look: repeatedly merging any
overlapping pair until none remain is correct, but it is O(n^2) and much harder
to convince yourself of.

## Edge cases

- Empty input. Returns empty; a fold that reads the first element before
  checking will raise.
- One interval. Returns it unchanged, ideally not the same mutable object.
- Touching intervals: `[[1, 4], [4, 5]]`. Merging gives `[[1, 5]]`, not merging
  gives both. Either is fine if stated; silently depending on `<` versus `<=`
  is the actual mistake.
- Full containment: `[[1, 10], [2, 3]]` is `[[1, 10]]`. This is the case that
  catches `end = next.end` instead of `end = max(end, next.end)`.
- Duplicates: `[[1, 2], [1, 2]]` is `[[1, 2]]`.
- Zero-width: `[[3, 3]]`, and `[[1, 5], [3, 3]]` which is `[[1, 5]]`.
- Already sorted input, and reverse-sorted input. Neither should matter, and a
  solution that only works on the first is a solution that forgot to sort.
- Negative numbers, if the type allows them.

## Common mistakes

- Taking the next interval's `end` rather than the maximum. Looks right on the
  first example, which is sorted so it never bites, and fails on containment.
- Sorting by `end`, or by both fields. Sorting by `end` can be made to work
  scanning the other direction, but mixed with a left fold it produces
  silently wrong output on containment.
- Mutating the caller's intervals while folding, so the input is wrecked and a
  second call on the same list gives a different answer.
- Comparing against the *original* previous interval rather than the growing
  merged one, which breaks on three-way chains like
  `[[1, 3], [2, 5], [4, 8]]` (one interval, `[1, 8]`).
- Forgetting to push the final accumulated interval after the loop ends.

## Hint ladder

1. Take the second example, `[[1, 4], [0, 5]]`, and your first example. What is
   true about the first one that makes it easier to think about?
2. If the intervals were in a helpful order, you would only ever need to compare
   each interval with one other interval. Which order, and which one?
3. Solve a smaller version first: given an already-merged list and one new
   interval whose `start` is at least every `start` already in the list, where
   can the new interval possibly go? There are only two cases.
4. ```
   sort intervals by start
   result = [first interval]
   for each remaining interval:
       if it starts within reach of result's last:
           # one line goes here, and it is not "= interval.end"
       else:
           append it to result
   ```

## What to notice (predict-then-compare)

- Did the plan name an order for the input before describing any comparison? A
  plan that compares first and sorts later usually grows extra cases.
- Did the plan commit to an answer on touching intervals, or leave it to
  whatever the operator happened to be?
- Did the plan say what the running time would be, and does the finished code
  match that claim? This is the exercise's real lesson: the sort is the cost,
  and the fold is nearly free.
