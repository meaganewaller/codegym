---
slug: line-diff
title: Diff two files by line
summary: Produce the edits that turn one list of lines into another, and the shortest set of them.
difficulty: hard
topic: algorithms
minutes: 45
published_at: 2026-09-20 09:00:00
---

## The problem

Given two lists of lines, produce a diff: a sequence of operations, each one
keeping a line, deleting a line from the first list, or inserting a line from
the second. Applying the operations to the first list must produce the second.

```
a = ["one", "two", "three", "four"]
b = ["one", "three", "four", "five"]

  one
- two
  three
  four
+ five
```

Among all the operation sequences that work, return one with the fewest
insertions and deletions.

```
a = ["x"], b = ["y"]   ->   - x / + y     (not: keep nothing, insert y, delete x)
a = [], b = []         ->   (empty)
```

## Before you code

- Write down a sequence of operations that is *correct but bad* for the first
  example: delete everything, then insert everything. It applies cleanly. What
  exactly makes the expected answer better, stated as a number you could compute?
- Once you have that number, you have an optimization problem. What are you
  choosing between at each step?
- If line 1 of `a` equals line 1 of `b`, is keeping them always at least as good
  as any alternative? Try to convince yourself, and notice whether you actually
  can.
- Two files of 10,000 lines that are identical except for one inserted line.
  What would you like the cost of that to be, and does your approach achieve it?
- How will you test this? "The output looks right" will not survive the third
  edge case.

## Stretch

Group the output into hunks with a few lines of context either side, in the
style of `diff -u`, including the `@@` line numbers. Then say what your diff
does with a file that does not end in a newline.
