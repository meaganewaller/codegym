---
slug: promise-pool
title: Run tasks with bounded concurrency
summary: Keep exactly N jobs in flight over a long list, and get the results back in order.
difficulty: medium
topic: async
minutes: 30
published_at: 2026-12-08 09:00:00
---

## The problem

Given a list of asynchronous tasks and a concurrency limit `n`, run them so that
at most `n` are in flight at any moment, starting a new one as soon as any
finishes. Return the results in the same order as the input tasks, not in the
order they completed.

```
tasks   = [a, b, c, d, e]        durations: a=30ms b=10ms c=10ms d=10ms e=10ms
limit   = 2

in flight: a,b -> b ends, start c -> c ends, start d -> d ends, start e
             -> e ends, then a ends
results: [a, b, c, d, e]         input order, not completion order
```

Do not start all the tasks and limit afterwards: at no point may more than `n`
be running.

## Before you code

- Sketch what is in flight at each moment for the example above. Does your
  approach start `c` the instant `b` finishes, or does it wait for both `a` and
  `b`? Those are different algorithms and one of them is much slower.
- The results come back in input order while completing out of order. What does
  that tell you about where a result has to be written?
- One task fails. What should happen to the ones already running, the ones not
  yet started, and the overall result? There are at least three defensible
  policies — name yours.
- What should happen with an empty task list, and with a limit larger than the
  number of tasks?
- Does your design need a queue, or is there an index that does the same job?

## Stretch

Make failures not cancel the run: return a result per task saying whether it
succeeded or failed, so one bad task cannot hide the other four outcomes. Then
add a retry with backoff for failures only, and say how retries interact with
the concurrency limit.
