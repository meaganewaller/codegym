---
slug: trie-autocomplete
title: Autocomplete with a trie
summary: Store a dictionary so that every completion of a prefix can be found without scanning it.
difficulty: medium
topic: data-structures
minutes: 30
published_at: 2026-08-23 09:00:00
---

## The problem

Build a structure with two operations:

- `insert(word)` adds a word to the dictionary.
- `complete(prefix)` returns every word in the dictionary that starts with the
  prefix.

```
insert("car"); insert("cart"); insert("carton"); insert("dog")

complete("car")  ->  ["car", "cart", "carton"]
complete("cart") ->  ["cart", "carton"]
complete("z")    ->  []
complete("")     ->  all four words
```

Finding the completions must not require looking at words that do not share the
prefix.

## Before you code

- Is `"car"` itself a completion of `"car"`? Say so explicitly; it is the first
  thing to get wrong.
- After `insert("cart")`, is `"car"` in the dictionary? Your structure will have
  something at `c-a-r` either way, so what distinguishes a word that was
  inserted from a path that merely passes through?
- In what order should completions come back, and does your approach give you
  that order for free or do you have to pay for it?
- What does `complete("")` return, and does your code reach that answer by the
  same route as any other prefix?
- Suppose the dictionary holds a million words and the prefix matches 50,000 of
  them. What would you want the signature to be then?

## Stretch

Each word now arrives with a frequency, and `complete(prefix, k)` must return
only the `k` most frequent completions. Do it without collecting every
completion first and sorting, and say what you store to make that possible.
