## Reference approach

Topological sort. Two standard shapes, and the choice matters for the error
message:

**Kahn's algorithm.** Count, for each job, how many of its dependencies are
unsatisfied. Put every job with a count of zero in a ready queue. Repeatedly
take a job from the queue, append it to the output, and decrement the count of
each job that depends on it, enqueueing any that reach zero. If the output is
shorter than the job list when the queue empties, the jobs missing from the
output are exactly those in or downstream of a cycle.

**Depth-first search with three colors.** Mark each job white (unvisited), gray
(on the current stack) or black (finished). Visit dependencies first, then
append the job. Meeting a gray job is a cycle, and the current stack *is* the
cycle, which is how you name it.

Both are O(jobs + dependencies).

The three-color distinction is the answer to the third question, and the thing
most first attempts get wrong: a two-state visited flag cannot tell "I am
currently inside this job" from "I finished this job earlier", so it reports a
diamond-shaped dependency graph — `d` depends on `b` and `c`, both of which
depend on `a` — as a cycle. That graph is perfectly legal and extremely common,
which is why it is worth constructing as a test.

Kahn's gives you *that a cycle exists* cheaply and the full set of implicated
jobs, but not a specific cycle. DFS gives you one concrete cycle with its path.
If the user wants the good error message, DFS is the easier route; if they want
the parallel groups in the stretch, Kahn's by levels is almost free. Worth
saying out loud, because the stretch rewards the other choice.

## Edge cases

- No jobs at all: empty order.
- Jobs with no dependencies at all: any order is valid, which makes assertions
  on exact output fragile.
- A diamond: `d -> [b, c]`, `b -> [a]`, `c -> [a]`. Legal. The two-state-flag
  bug reports this as a cycle.
- A job depending on itself: `a -> [a]`. A cycle of length one, and a case many
  implementations miss because the check is written for length two or more.
- Two separate components with no connection between them.
- A dependency naming a job that does not exist.
- Duplicate dependencies: `b -> [a, a]`. With in-degree counting this
  double-counts and `b` never becomes ready, which is a genuinely nasty bug.
- A long chain, deep enough to blow the stack in the recursive version.
- A cycle plus some perfectly fine jobs. The fine ones should still be reported
  usefully, and the error should not claim the whole set is cyclic.

## Common mistakes

- A single visited flag instead of three states, so legal diamonds are reported
  as cycles. The most common failure here by a wide margin.
- Edge direction reversed, producing an order where dependencies run last. The
  symptom is a correct-looking algorithm and an exactly backwards answer, and
  `reverse` makes it pass without the confusion being resolved.
- Counting in-degree from a dependency list with duplicates, so a job is never
  released.
- Detecting the cycle but reporting only that one exists, when the statement asks
  which jobs. Usually because the information was available and then discarded.
- Appending the job to the output *before* visiting its dependencies in the DFS
  version, which reverses the order within each branch.
- Mutating the input graph while iterating it, so a second call gives a
  different answer.
- Treating a missing dependency as satisfied silently, so a typo in a job name
  turns into a job that runs too early rather than an error.
- Recursion without a depth guard on a long chain.

## Hint ladder

1. For the first example, write down two valid orders. Now, for each job, write
   what had to be true at the moment you were allowed to place it. You have just
   described the algorithm.
2. A job is placeable when every job it depends on is already placed. So either
   repeatedly find the placeable ones, or go depth-first and place a job only
   after placing everything beneath it. Both work; they give you different
   things when it fails.
3. Solve a smaller problem first: ignore cycles entirely and produce a valid
   order for a graph you know is acyclic. Test it on the diamond. Only then add
   detection, and start by asking what state a job can be in while you are in
   the middle of visiting it.
4. ```
   # Kahn's
   indegree[j] = number of distinct deps of j not yet placed
   ready = [ j for j in jobs if indegree[j] == 0 ]
   while ready:
       j = ready.pop(); output.append(j)
       for k in dependents_of(j):
           indegree[k] -= 1
           if indegree[k] == 0: ready.append(k)
   # one comparison at the end tells you a cycle existed. which one?
   ```

## What to notice (predict-then-compare)

- Did the plan distinguish "currently being visited" from "already done"? If
  there is one visited flag, the diamond test will fail, and that test is worth
  writing before the code.
- Did the plan say which jobs it would be able to name when it fails? The
  algorithm choice decides that, and choosing before coding is the point.
- Did the plan notice that valid output is not unique, and that tests therefore
  need to check the *property* rather than an exact list? That habit transfers
  well beyond this problem.
- Did the user pick Kahn's or DFS for a stated reason? Either is right; picking
  without noticing the trade-off means the stretch or the error message will
  force a rewrite.
