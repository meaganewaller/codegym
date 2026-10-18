---
slug: rate-limiter
title: Rate limit by key
summary: Allow at most N actions per window per user, and decide what a window even is.
difficulty: medium
topic: systems
minutes: 30
published_at: 2026-08-30 09:00:00
---

## The problem

Write a rate limiter with one operation:

`allow?(key, now)` returns true if this action is permitted and false if the
caller has exceeded the limit. Configure it with a limit and a window, for
example 3 actions per 10 seconds, and keep separate counts per key.

With a limit of 3 per 10 seconds:

```
allow?("ana", t=0)   -> true     1 used
allow?("ana", t=1)   -> true     2 used
allow?("ana", t=2)   -> true     3 used
allow?("ana", t=3)   -> false    over the limit
allow?("bo",  t=3)   -> true     different key, own budget
allow?("ana", t=11)  -> true     the first actions have aged out
```

Take `now` as an argument rather than reading the clock inside.

## Before you code

- At `t=11`, exactly which earlier actions should no longer count? Write the
  rule down. There is more than one reasonable rule, and they disagree about
  `t=10`.
- Consider a caller who makes 3 requests at `t=9` and 3 more at `t=11`. Is that
  acceptable under your rule? Is it acceptable to you?
- What does the limiter remember per key, and how does that grow with traffic?
  What happens to a key nobody has used for a week?
- Does `allow?` returning false count as an action?
- `now` is a parameter here instead of a call to the clock inside the limiter.
  Say what that buys. You will want the same answer when you test it.

## Stretch

Return more than a boolean: how long the caller should wait before trying again.
Then say what two processes sharing one limiter would need for your answer to
stay true, and what breaks if they each keep their own copy.
