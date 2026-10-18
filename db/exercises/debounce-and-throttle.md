---
slug: debounce-and-throttle
title: Debounce and throttle
summary: Two ways to make a function called too often behave, and they are not the same way.
difficulty: medium
topic: async
minutes: 30
published_at: 2026-12-01 09:00:00
---

## The problem

Write two wrappers that each take a function and a delay and return a new
function.

- `debounce(fn, delay)` calls `fn` once the calls have stopped: each new call
  cancels the pending one and restarts the clock.
- `throttle(fn, delay)` calls `fn` at most once per delay, no matter how often
  it is called.

With a delay of 100ms, and calls at 0, 50 and 90ms:

```
debounce  ->  fn runs once, at 190ms      (100ms after the last call)
throttle  ->  fn runs once, at 0ms        (the first call; the rest are inside the window)
```

With calls at 0, 150 and 300ms:

```
debounce  ->  fn runs three times, at 100, 250 and 400ms
throttle  ->  fn runs three times, at 0, 150 and 300ms
```

## Before you code

- Say in one sentence each what debounce is *for* and what throttle is *for*,
  with a concrete situation. If the two sentences could be swapped without
  anyone noticing, keep going until they could not.
- Does throttle run on the first call or at the end of the first window? Both
  exist in the wild and they behave differently on a single isolated call.
- When the wrapped function finally runs, which call's arguments does it get —
  the first, the last, or all of them?
- What does the wrapper return to its caller? The function it wraps has a return
  value and the wrapper usually cannot produce it.
- Does your throttle do anything about calls that arrive and are dropped? Should
  the last one eventually run?

## Stretch

Give each wrapper a `cancel` that discards anything pending, and give debounce a
`flush` that runs it immediately. Then say what should happen if `cancel` is
called from inside `fn` itself.
