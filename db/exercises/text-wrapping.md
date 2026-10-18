---
slug: text-wrapping
title: Wrap text to a width
summary: Break a paragraph into lines that fit a column, deciding what counts as a good break.
difficulty: easy
topic: algorithms
minutes: 30
published_at: 2026-11-03 09:00:00
---

## The problem

Given a string of text and a maximum line width, return a list of lines. No
line may be longer than the width, and lines break at spaces rather than in the
middle of words.

```
wrap("the quick brown fox", 10)  ->  ["the quick", "brown fox"]
wrap("a bb ccc", 3)              ->  ["a", "bb", "ccc"]
wrap("", 10)                     ->  []
```

## Before you code

- What happens to a single word that is longer than the width? There are two
  defensible answers and they produce different function signatures. Pick one
  and say why.
- Is a run of several spaces preserved, or treated as one break? What about a
  newline already in the input?
- Does a space at the end of a line count against the width?
- Write one sentence on what would make one set of line breaks *better* than
  another, given both fit. You do not have to implement that, but say whether
  your approach achieves it.

## Stretch

Implement the better answer to that last question: break the text so the lines
are as even as possible rather than merely legal, where unevenness is the sum
over all lines of the squared leftover space. Compare its output to your first
version on a paragraph where they differ.
