## Reference approach

A single cursor over the input and a dispatch on the character under it. Skip
whitespace; on a digit, consume the longest run of digits with at most one dot;
on a letter or underscore, consume the longest run of identifier characters; on
an operator character, try the two-character operators before the one-character
ones; otherwise report an error carrying the offending character and its offset.

O(n), one pass, no backtracking. Each branch is responsible for advancing the
cursor past exactly what it consumed, which is where most bugs live.

The rule the "before you code" questions are fishing for is **maximal munch**:
at each position take the longest token that matches. It is the thing that
scales, because adding `>>=` means adding a longer candidate rather than
rewriting the `>` case.

The alternative is one big regular expression with alternation, ordered longest
first, matched at the cursor — genuinely the right tool in most languages, and
it is the same rule expressed differently, since the alternation order *is* the
munch order. If the user writes the regex version, the useful question is what
happens when they reorder the alternatives, because putting `>` before `>=`
breaks it in a way no test of single-character operators will catch.

Table-driven and state-machine versions exist and are what a generator emits.
Overkill by hand, worth naming if the user is heading toward a real language.

## Edge cases

- Empty string, and a string of only whitespace: an empty token list.
- A two-character operator at the very end of the input, like `"1 >="`. The
  lookahead must not read past the end.
- `>` alone, `>=`, and `>==` which is `>=` followed by `=`.
- `!` alone, which is not in the operator list, unlike `!=`.
- A number with no digits after the dot, `"3."`, and one with no digits before
  it, `".5"`.
- `3.5.7`, which maximal munch makes `3.5` then `.7` unless the number scanner
  forbids a second dot and says so.
- An identifier starting with a digit, `"1abc"`. Falls out as `1` then `abc`
  unless you choose to reject it, and either is fine if stated.
- Unknown characters, including a non-ASCII one.
- No whitespace at all: `"1+2"` must tokenize the same as `"1 + 2"`.

## Common mistakes

- Checking one-character operators first, so `>=` always arrives as `>` then
  `=`. The classic. A test suite that only exercises `+ - * /` never sees it.
- Forgetting to advance the cursor in some branch, giving an infinite loop. Nearly
  always the error branch or the whitespace branch.
- Advancing by one after consuming a multi-character token, dropping its last
  character.
- Lookahead that reads `input[i + 1]` without checking the length, which either
  raises or silently reads a nil that compares unequal to everything.
- Returning bare strings as tokens, so the caller cannot tell the identifier
  `x` from a hypothetical operator `x`, and cannot tell `"42"` the number from
  `"42"` the text. The type belongs in the token.
- Accumulating characters into a string with `+=` per character. Works, but ask
  what it costs on a long identifier.
- Swallowing errors by skipping unknown characters silently, so `"1 @ 2"`
  tokenizes as `1 2` and the bug surfaces in the parser instead.

## Hint ladder

1. Tokenize `"1 >= 2"` by hand, one character at a time, and write down what
   you know at the moment your finger is on the `>`. What do you need to look at
   before you can name that token?
2. There is a single rule that covers `>` versus `>=` and would also cover a
   future `>>=`, and it is about length. Say it out loud before you code it.
3. Solve a smaller problem first: write only the number scanner. Given the input
   and a start index, return the number token and the index just past it. Test
   it on `"3"`, `"3.5"`, `"3."` and `"3.5.7"` before writing anything else.
4. ```
   tokens = []; i = 0
   while i < len(input):
       c = input[i]
       if is_space(c):   i += 1
       elif is_digit(c): token, i = scan_number(input, i)
       elif is_ident_start(c): token, i = scan_ident(input, i)
       else:
           # try the LONGER candidates first -- that is the whole trick
           # and remember i + 1 may be past the end
   ```

## What to notice (predict-then-compare)

- Did the plan state the maximal-munch rule, or enumerate the operator pairs
  one by one? Both work today; only one survives a new operator.
- Did the plan say what each scanner returns? The ones that return only the
  token, and track the cursor in a shared variable, tend to produce the
  off-by-one advancement bugs.
- Did the plan decide what a token *is* before writing the loop? A plan that
  says "a list of strings" has already lost information it will want back.
- Was the position question answered with a user in mind? The next exercise,
  the expression evaluator, is that user.
