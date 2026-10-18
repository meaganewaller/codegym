---
slug: tokenizer
title: Tokenize an expression
summary: Turn a line of source text into a list of tokens, including the ones made of two characters.
difficulty: medium
topic: parsing
minutes: 30
published_at: 2026-08-16 09:00:00
---

## The problem

Write a tokenizer that turns a string into a list of tokens. You need to handle
integers and decimals, identifiers, the operators `+ - * / < > <= >= == !=`,
and parentheses. Whitespace separates tokens but is not itself a token.

```
"1 + 2*30"      ->  [num 1] [op +] [num 2] [op *] [num 30]
"foo_1 >= 42"   ->  [ident foo_1] [op >=] [num 42]
"(3.5)"         ->  [lparen] [num 3.5] [rparen]
```

## Before you code

- When the scanner is sitting on a `>`, how does it decide whether it is looking
  at `>` or at `>=`? State the rule in one sentence, in a way that would still
  work if `>>=` were added tomorrow.
- What ends a number? What ends an identifier? Answer separately.
- What should happen on a character you do not recognize, such as `@`? Decide
  what the caller is told and what they can do with it.
- Should a token know where in the input it came from? Who would want that, and
  what does it cost you to carry it?
- Is `3.5.7` one token, two, or an error? Where does your answer get decided?

## Stretch

Add string literals in double quotes, with `\"` as an escape for a quote inside
one. Then say what your tokenizer does with an unterminated string, and make
sure it says something useful rather than running off the end.
