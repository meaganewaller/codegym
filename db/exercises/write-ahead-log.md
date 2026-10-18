---
slug: write-ahead-log
title: A key-value store with a write-ahead log
summary: Survive being killed mid-write, by deciding what "committed" means before you crash.
difficulty: hard
topic: systems
minutes: 45
published_at: 2027-01-05 09:00:00
---

## The problem

Build a key-value store with `set(key, value)`, `get(key)` and `delete(key)`
that survives the process being killed at any moment. On startup it must recover
every operation that was acknowledged before the crash, and must not invent any
that were not.

The approach is a write-ahead log: append a record describing the operation to a
file, and only then change the in-memory state.

```
set("a", "1"); set("b", "2"); delete("a")
    -- process killed --
restart
get("a") -> miss
get("b") -> "2"
```

Simulate the crash by exiting without any cleanup, then constructing a new store
over the same file.

## Before you code

- `set` returns to its caller. At that instant, what exactly do you promise? Be
  precise about whether the bytes are in your process, in the operating system,
  or on the disk — they are three different promises.
- The process is killed in the middle of appending a record, so the last line of
  the file is half written. What does recovery do with it? Say how it can even
  tell.
- How do you represent a delete? A missing key and a deleted key have to be
  distinguishable while replaying.
- The log grows forever, including records for keys overwritten a thousand times.
  What would you do about that, and what new failure does your fix introduce?
- A value containing a newline, or whatever your record separator is. What
  happens?

## Stretch

Add compaction: write the current state to a new file, then atomically replace
the log with it. The hard part is not the writing — it is being killed partway
through the replacement and still recovering. Say which single operation you are
relying on to be atomic, and check that it really is.

## A note on this one

This is the hardest of the starter set and 45 minutes is not generous. Getting a
clear answer to the first two questions and a partial implementation is a better
outcome than a finished store built on a vague promise.
