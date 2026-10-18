## Reference approach

A sliding log. Per key, keep the timestamps of permitted actions in a queue. On
`allow?`, first drop every timestamp older than `now - window`, then compare the
queue's length to the limit; if under, append `now` and return true, else return
false.

O(number of expired entries) amortized per call, O(limit) memory per active key.
Exact, easy to reason about, and the version to write first.

The alternatives, and this exercise is really about the choice between them:

**Fixed window.** A counter plus the window's start time; when `now` moves past
the window, reset both. One integer per key, and the reason the second "before
you code" question exists: 3 requests at `t=9` and 3 at `t=11` is 6 in two
seconds, legal under fixed windows and usually not what anyone meant. Fine when
the limit is a billing quota, wrong when it is protecting a server.

**Sliding window counter.** Weight the previous window's count by how much of it
still overlaps. Constant memory, approximate, and what most production limiters
actually do.

**Token bucket.** Tokens accrue at `limit / window` per unit time up to a cap;
each action spends one. Two numbers per key, naturally allows a burst up to the
cap and then a steady rate, and composes well with the stretch's retry-after.
This is the answer most real systems want, and a user who proposes it has
understood the problem better than the reference approach has.

If the user writes the log, ask what it costs when the limit is 10,000. If they
write fixed windows, ask about the boundary. Either question lands.

## Edge cases

- The very first call for a key, with nothing stored.
- `t=10` exactly, with a 10-second window. Inclusive or exclusive is a decision;
  `<` versus `<=` is where it lives.
- A denied call. Must not consume budget, or a caller who keeps retrying while
  blocked never recovers. This is the one that matters most in production.
- Limit 0: nothing is ever allowed. Limit 1: the common case for a login form.
- Two calls with the same `now`.
- `now` going backwards, which happens with wall-clock time and NTP. Decide
  whether to clamp or ignore it.
- Keys never seen again: unbounded memory growth. The queue per key shrinks, but
  the map of keys does not, and nothing in the stated interface sweeps it.
- A key used exactly at the window boundary repeatedly, which is the pattern
  that reveals fixed-window burst doubling.

## Common mistakes

- Counting denied attempts, so a hammering client stays locked out forever.
- Pruning after the length check instead of before, which denies a caller whose
  entries have all expired.
- Resetting the whole structure rather than per key, so one busy user clears
  everyone's budget.
- Reading the clock inside `allow?`, which makes the window boundary untestable
  without sleeping. The exercise hands this one over in the questions; notice
  whether the user understood why.
- A single shared counter because the key was threaded through the storage but
  not the prune.
- Storing timestamps in a list and scanning the whole list each call, which is
  the same asymptotics as the queue but quietly O(limit) rather than amortized
  O(expired). Not wrong, worth seeing.
- Assuming one process. Two workers with separate in-memory limiters give double
  the limit, which is the stretch's real answer and a genuine outage cause.

## Hint ladder

1. Take the worked example and write down, just before the call at `t=3` and
   again just before `t=11`, exactly what you would need to have remembered to
   answer correctly. Compare the two.
2. The answer at `t=11` depends on *when* the earlier actions happened, not just
   how many there were. That tells you what to store.
3. Solve a smaller problem first: write only `prune(key, now)`, which removes
   the entries that no longer count. Test it directly, including at the exact
   boundary, before writing any allow/deny logic.
4. ```
   allow?(key, now):
       queue = store[key]
       # one step happens here, and it is not the length check
       if queue.length < limit:
           queue.push(now)
           return true
       return false      # note what did NOT happen on this path
   ```

## What to notice (predict-then-compare)

- Did the plan state the expiry rule before any code, and does it answer `t=10`?
  An unstated rule becomes whichever comparison operator got typed.
- Did the plan say that a denial costs nothing? This is the difference between a
  limiter and a lockout, and it is invisible in a test that never exceeds the
  limit.
- Did the plan notice memory growth in the key map, as opposed to the per-key
  queue? Almost nobody does on the first pass.
- Did the user say what taking `now` as a parameter buys? If the answer was
  about testing, they have found the habit this exercise is really teaching.
