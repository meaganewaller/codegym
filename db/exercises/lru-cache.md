---
slug: lru-cache
title: Build an LRU cache
summary: A fixed-capacity key-value store that evicts whatever was used longest ago.
difficulty: medium
topic: data-structures
minutes: 30
published_at: 2026-08-02 09:00:00
---

## The problem

Build a cache with a fixed capacity and two operations:

- `get(key)` returns the stored value, or a miss if the key is absent.
- `put(key, value)` stores the value. If the cache is already at capacity and
  the key is new, first evict the key that was used longest ago.

With capacity 2:

```
put(1, "a")        cache holds 1
put(2, "b")        cache holds 1, 2
get(1)      -> "a"
put(3, "c")        evicts 2, because 1 was just used
get(2)      -> miss
get(3)      -> "c"
```

Both operations should run in constant time, not time proportional to the number
of keys held.

## Before you code

Answer these in writing first. The first two are specification questions, and
your answers decide what "correct" means for the rest.

- Does a `get` that misses count as using the key?
- Does a `put` that overwrites a key already in the cache count as using it?
- What should capacity 0 do, and what about a negative capacity?
- You need to find a key immediately, and separately to know which key was used
  longest ago. Which of those does the obvious structure give you, and which one
  are you going to have to build?
- When you evict, how many places need to hear about it? Count them before you
  write the eviction code.

## Stretch

Add a maximum age: an entry older than `ttl` seconds is a miss even if it has
not been evicted, and should not keep a fresher entry out of the cache. Decide
whether expired entries are removed eagerly or when encountered, and what that
choice costs.
