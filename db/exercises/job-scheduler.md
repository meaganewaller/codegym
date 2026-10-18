---
slug: job-scheduler
title: Order jobs by their dependencies
summary: Work out a safe order to run jobs that depend on each other, and refuse the impossible ones.
difficulty: hard
topic: systems
minutes: 45
published_at: 2026-12-29 09:00:00
---

## The problem

You are given jobs, each with a list of other jobs it depends on. Return an
order in which every job runs after everything it depends on. If no such order
exists, say so and say which jobs are involved.

```
migrate   depends on []
seed      depends on [migrate]
assets    depends on []
deploy    depends on [seed, assets]

-> migrate, assets, seed, deploy        (one valid answer among several)
```

```
a depends on [b]
b depends on [a]

-> no valid order; a and b form a cycle
```

## Before you code

- The first example has more than one valid answer. Write down two. What is
  common to every valid answer, and what is free to vary?
- How do you know when a job is ready to run? Say it as a condition on the job
  rather than as a procedure.
- Your detection of "no valid order" has to distinguish a genuine cycle from a
  job you simply have not reached yet. What is the difference, concretely?
- A job depends on something that is not in the list at all. Error, or
  implicitly satisfied? Decide.
- The error message should name the jobs in the cycle, not just say a cycle
  exists. Does your approach still know which ones they were when it finds out?

## Stretch

Return the order as groups that could run in parallel: every job in group `k`
depends only on jobs in earlier groups. Then say what the number of groups tells
you about the whole job set.

## A note on this one

If this is taking longer than 45 minutes, stop and write down where the time
went. The cycle reporting is usually where it goes, and that is worth knowing
about yourself.
