## Reference approach

Recursive descent, one function per precedence level:

```
expression := term   (('+' | '-') term)*
term       := factor (('*' | '/') factor)*
factor     := NUMBER | '(' expression ')' | '-' factor
```

Each level loops while it sees an operator of its own precedence, calling the
next level down for its operands. Left associativity comes out of the loop:
folding as you go gives `(10 - 4) - 3`. Precedence is encoded in the *ordering
of the functions* — `expression` calls `term`, so `term` binds tighter. Unary
minus belongs in `factor` and recurses into `factor`, which is what makes
`-(-3)` and `2 * -3` work.

O(n) in the number of tokens, with recursion depth proportional to nesting.

Right associativity for the stretch is one change: `factor := base ('^' factor)?`
recursing into *itself* on the right rather than looping. That a one-line change
buys right associativity is the strongest signal the structure is right, which
is why the stretch asks.

The main alternatives:

**Shunting-yard**, Dijkstra's: one pass with an operator stack and an output
queue, precedence as a table of numbers, evaluating as it pops. Precedence lives
in data rather than in code structure, which is better when operators are
user-extensible and worse when you want good error messages, since the stack has
no idea what it was expecting.

**Pratt parsing**, or precedence climbing: one function with a binding-power
number per operator. This is what most real language implementations use, it
handles prefix and infix uniformly, and right associativity is a `±1` on a
binding power. If the user gets here, they have found the good answer.

Evaluating with the host language's `eval` is the joke answer, and the genuinely
useful follow-up is to ask what happens when the input comes from a web form.

## Edge cases

- `"10 - 4 - 3"` = 3. The associativity case. A naive recursive `expression :=
  term '-' expression` gives 9, and the structure *looks* fine.
- `"2 * -3"` and `"-5 + 3"`: unary minus after an operator and at the start.
- `"--3"`, which is 3 if unary minus recurses into factor.
- `"2 - -3"` = 5, which catches code that decides unary versus binary by
  position in the string rather than by context.
- `"(1 + 2) * (3 - 1)"` and nested parens.
- Errors: `""`, `"2 +"`, `"(1 + 2"`, `"1 + )"`, `"1 2"`, `"()"`. Each needs a
  decision. `"1 2"` is the sneaky one — many implementations evaluate `1` and
  silently ignore the rest, which is worse than failing.
- `1 / 0`, and `0 / 0`.
- Integer versus float division on `"6 / 4"`. Both defensible; silently doing
  integer division when the input had a decimal point is not.
- Deep nesting, enough to blow the stack.
- Whitespace everywhere and nowhere: `"1+2"` and `"  1  +  2  "`.

## Common mistakes

- Right-recursing on the binary operators, making `-` and `/` right
  associative. The bug is in `"10 - 4 - 3"` and nowhere else that a casual test
  would look, which is why that example is in the statement.
- Precedence inverted, so `expression` is called by `term`. Produces 9 for
  `"1 + 2 * 3"`.
- Unary minus handled by peeking at the previous character rather than by
  grammar position, which then fails on `"2 - -3"` or on whitespace variation.
- Unary minus parsed as `-` followed by a *term*, so `"-2 * 3"` becomes
  `-(2 * 3)`. Same answer here, different answer with `^` in the stretch.
- Not checking that all tokens were consumed, so `"1 2"` returns 1. The fix is
  one assertion at the top level, and almost nobody writes it unprompted.
- Reading past the end of the token list when the expression is truncated,
  giving an index error rather than a message.
- Parsing and evaluating so entangled that the stretch requires a rewrite. Worth
  noting rather than correcting: building a tree first costs a little and pays
  for itself the moment anything else needs the expression.
- Floating point surprises, then asserting exact equality in tests.

## Hint ladder

1. Evaluate `"1 + 2 * 3"` by hand and write down the order you did the
   operations in. Now do `"10 - 4 - 3"`. In each case, which operation did you
   perform *last*? That is the top of your tree.
2. The operation performed last is the one that binds *loosest*. If you had one
   function per precedence level, which function would see the `+`, and which
   would see the `*`?
3. Solve a smaller problem first: write an evaluator for addition and
   subtraction only, no `*`, no parens, no unary minus. Make `"10 - 4 - 3"`
   return 3. Get that loop right, because every other level has the same shape.
4. ```
   expression():            # + and -
       value = term()
       while peek() in ('+', '-'):
           op = next(); value = apply(op, value, term())   # note: fold AS YOU GO
       return value

   term():                  # * and / -- same shape, calls factor()
   factor():                # NUMBER, or '(' expression ')', or '-' factor
   ```

## What to notice (predict-then-compare)

- Did the plan say where associativity lives? "A loop rather than recursion on
  the right" is the answer; anything vaguer usually produces 9 for the
  subtraction example.
- Did the plan point at a *concrete* encoding of precedence — the call ordering,
  or a table of numbers? If it just says "handle precedence", the code will
  discover it the hard way.
- Did the plan decide unary minus by grammar position or by looking backwards at
  characters? The second works until it does not.
- Did the plan include "and then check there are no tokens left"? Its absence is
  the single most common hole in a working evaluator.
