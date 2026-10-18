## Reference approach

Greedy, one pass. Split on whitespace, then keep a current line; for each word,
if the current line is empty take the word, else if the current length plus one
plus the word's length fits, append a space and the word, otherwise push the
current line and start a new one with the word. Push whatever is left at the end.

O(n) in the length of the text, O(n) output.

The alternative is minimum-raggedness wrapping, the Knuth-Plass idea in its
simple form: `cost(i)` is the best total cost of wrapping words `i..end`, where
a line's cost is the square of its leftover space, computed by trying every
possible last word on the first line. Straightforward dynamic programming,
O(n^2) with memoization, or O(n * w) if you stop extending a line once it
overflows.

The trade-off is the point of this exercise. Greedy is optimal for *number of
lines* and nowhere near optimal for *evenness*, which is why every word
processor uses something closer to the second and every terminal tool uses the
first. If the user asserts greedy is optimal, that is the thing to probe: it is
optimal for a different objective than the one they probably mean.

## Edge cases

- Empty string. Returns an empty list, not a list holding one empty string.
- A word exactly equal to the width. Fits on its own line, and the off-by-one
  lives here: `length + 1 + word` versus `length + word`.
- A word longer than the width. Either hard-break it across lines or emit it
  over-long on a line of its own. Silently dropping it, or looping forever
  trying to fit it, are the two failure modes.
- Width 0 or negative. Worth deciding rather than discovering.
- Leading and trailing whitespace in the input.
- Runs of multiple spaces, and tabs, and an input that already contains
  newlines. A naive `split(" ")` yields empty strings between consecutive
  spaces, which then become zero-length words that consume width.
- A single word with no spaces at all.

## Common mistakes

- Forgetting the space when measuring, so lines come out one character over.
  Catching this needs a test where a word fits only without its space.
- `split(" ")` rather than splitting on runs of whitespace, so double spaces
  produce empty words.
- Losing the last line by pushing only inside the loop.
- Breaking mid-word by slicing at the width instead of at a space, which passes
  the first example by luck when the break happens to land on a space.
- Infinite loop on a word longer than the width: the line never fits, so the
  word is never consumed.
- Mutating a shared buffer and pushing the same object repeatedly, so every line
  in the result is the last one.

## Hint ladder

1. Wrap `"a bb ccc"` to width 3 by hand, writing down what you are holding in
   your head after each word. What is the smallest amount of state that is?
2. You only ever need to know the line you are currently building. Each word
   then presents exactly one question with two answers.
3. Solve a smaller problem first: write a function that takes the current line
   and the next word and returns whether the word can join that line. Get the
   space right there, in isolation, with a test for the exactly-fits case.
4. ```
   lines = []; current = ""
   for word in split_on_whitespace(text):
       if current is empty:
           current = word
       elif  # one condition here, and it has a +1 in it
           current = current + " " + word
       else:
           lines.append(current); current = word
   # one more line after the loop
   ```

## What to notice (predict-then-compare)

- Did the plan decide what happens to an over-long word *before* coding? That
  decision changes the signature, and discovering it late usually means a
  rewrite rather than an addition.
- Did the plan measure the separator? Ask where the `+ 1` is, before looking at
  the code.
- On the last question: did the user notice that greedy and good are different
  objectives? That is the transferable idea here, far more than the loop.
