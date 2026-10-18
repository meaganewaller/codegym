---
slug: merge-intervals
title: Merge overlapping intervals
summary: Collapse a list of ranges into the smallest set that covers the same ground.
difficulty: easy
topic: algorithms
minutes: 30
published_at: 2026-10-20 09:00:00
---

## The problem

You are given a list of intervals, each a pair of numbers `[start, end]` where
`start <= end`. Return the smallest list of intervals that covers exactly the
same ground, with no two intervals in the result overlapping.

```
[[1, 3], [2, 6], [8, 10], [15, 18]]  ->  [[1, 6], [8, 10], [15, 18]]
[[1, 4], [0, 5]]                     ->  [[0, 5]]
[]                                   ->  []
```

The input is in no particular order.

## Before you code

Write your answers down before you write any code. Two of these change the
shape of the solution, not just an edge case.

- Do `[1, 4]` and `[4, 5]` overlap? Both answers are defensible. Pick one, say
  why, and notice which comparison operator you just committed to.
- What do you return for an empty list, and for a single interval?
- May you reorder or mutate the caller's list? If not, what does that cost you?
- Which part of your approach decides the running time? Name it before you
  start, then check your finished code against your own claim.

## Stretch

The intervals now arrive one at a time from a stream and there are far too many
to hold in memory, but they arrive already sorted by `start`. What changes, and
what can you now do that you could not before?
