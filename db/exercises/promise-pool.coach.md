## Reference approach

A shared cursor plus `n` workers. Start `n` worker loops; each loop takes the
next index from the shared cursor, awaits that task, writes its result into
`results[index]`, and loops until the cursor runs past the end. Wait for all
workers to finish, then return `results`.

The two ideas that make it work: writing results **by index** rather than
appending preserves input order for free, and the worker loop means a finishing
task starts the next one immediately rather than at a batch boundary.

O(total task time / n) wall clock in the ideal case, O(n) concurrent resource
use, O(tasks) memory for the results.

The alternative, and the one almost everyone writes first, is **chunking**:
split the list into groups of `n` and await each group. It satisfies the letter
of the limit and is meaningfully slower, because each chunk takes as long as its
slowest member and the fast tasks sit idle waiting. In the worked example,
chunking gives `[a,b]` then `[c,d]` then `[e]`, so `c` cannot start until `a`'s
30ms is done. Worth measuring rather than asserting: the user can see it in the
example as written, which is why `a` is three times slower than the rest.

A third shape is a self-refilling pool: start `n`, and in each completion
handler start the next. Equivalent to the worker loop, usually messier, and
prone to the off-by-one where it starts `n+1` tasks.

If the language has a semaphore, acquiring one around each task and launching
them all is the idiomatic version, and it is the worker loop with the
bookkeeping done by the semaphore. Fine answer; ask what the semaphore is doing.

## Edge cases

- Empty task list. Returns an empty list and must not hang waiting for workers
  that have nothing to do.
- Limit greater than the number of tasks. Extra workers must exit immediately
  rather than block or read past the end.
- Limit 1, which should be plain sequential execution, and is a good test that
  ordering is right.
- Limit 0 or negative. Would hang forever if unguarded, so decide: raise, or
  treat as 1.
- A task that completes synchronously or instantly, which can recurse straight
  into the next start in the self-refilling version.
- One task much slower than all others, which is the case that exposes chunking.
- A task that fails immediately, before the others have started.
- Duplicate task objects in the list; results must still be per position.

## Common mistakes

- Appending results as tasks complete, so the order is completion order. Passes
  any test where all tasks take the same time, which is most hand-written tests.
- Chunking and believing it is a pool. The limit is respected, so it is not
  wrong, just slower than asked — the statement rules it out by saying a new
  task starts as soon as any finishes.
- A shared cursor read and incremented in two steps where the runtime can
  interleave, so two workers take the same index. In a single-threaded event
  loop this is safe and the reasoning is worth making explicit; in a threaded
  language it is a real race.
- Starting `n + 1` tasks, by starting `n` and then also starting one in the
  first completion handler before any has finished.
- Not awaiting the workers, so the function returns a half-filled array.
- A rejected task leaving the other workers running with nobody collecting them,
  producing unhandled rejections after the function has already returned. This
  is the subtle one and the reason the failure-policy question is in the list.
- Holding every task's result and also every task, so memory is O(tasks) when it
  could have been O(n) for a streaming consumer.

## Hint ladder

1. Fill in a table for the worked example: one row per 10ms, one column per
   in-flight slot. Write which task is in each slot. Now look at the moment `b`
   finishes — what has to happen in that instant?
2. Think of it as `n` identical workers sharing one to-do list, rather than as
   one scheduler handing out work. What does each worker need to know?
3. Solve a smaller problem first: write a single worker that drains the whole
   list sequentially, writing into `results[index]`. Confirm the order is right
   with tasks of deliberately different durations. Then run `n` copies of it.
4. ```
   results = array(len(tasks))
   cursor  = 0

   worker():
       while true:
           i = cursor; cursor += 1      # one index each, and see the note above
           if i >= len(tasks): return
           results[i] = await tasks[i]()   # note WHERE this is written

   await all( worker() for _ in range(min(limit, len(tasks))) )
   ```

## What to notice (predict-then-compare)

- Did the plan start the next task on each completion, or at a batch boundary?
  The example is built so the difference is visible, and this is the exercise's
  whole point.
- Did the plan say results are written by index? If it said "collect the
  results", expect completion order in the code.
- Did the plan pick a failure policy, or leave it to whatever the language's
  `all` does by default? The default usually abandons in-flight work in a way
  nobody chose.
- Did the user reason about whether their cursor increment is safe in their
  language? Being right for a stated reason is different from being right
  because the runtime happens to be single-threaded.
