---
slug: expression-evaluator
title: Evaluate an arithmetic expression
summary: Parse and evaluate infix arithmetic with precedence, parentheses and unary minus.
difficulty: hard
topic: parsing
minutes: 45
published_at: 2026-09-27 09:00:00
---

## The problem

Evaluate an arithmetic expression given as a string. Support `+ - * /`, integers
and decimals, parentheses, and unary minus. Multiplication and division bind
tighter than addition and subtraction, and operators of equal precedence
associate left to right.

```
"1 + 2 * 3"       ->  7       not 9
"(1 + 2) * 3"     ->  9
"10 - 4 - 3"      ->  3       not 9
"-5 + 3"          ->  -2
"2 * -3"          ->  -6
```

You may reuse the tokenizer exercise, or split the string however you like;
the interesting part starts after you have tokens.

## Before you code

- `"10 - 4 - 3"` is 3, not 9. Say precisely what rule produces 3, and where in
  your design that rule is going to live.
- How does your design know that `*` binds tighter than `+`? Point at the
  specific thing — a number, an ordering, a function call — that encodes it.
- `-` is two different operators. How does your code tell which one it is
  looking at? The answer is about what came *before* it.
- What does `"2 +"` do? What about `"(1 + 2"`, or `"1 2"`, or `""`? Decide now,
  because these are most of the cases you will hit.
- What is `1 / 0`? And is `"6 / 4"` equal to 1 or 1.5? State both answers before
  you write any arithmetic.

## Stretch

Add a right-associative `^` for exponentiation, so `"2 ^ 3 ^ 2"` is 512 and not
64. If your design handles that by changing one number or one line, it was the
right design; if it needs a new function, say what that tells you.

## A note on this one

If this is taking longer than 45 minutes, stop and write down where the time
went. "Where it got hard" is more useful to bring to a debrief than a finished
evaluator.
