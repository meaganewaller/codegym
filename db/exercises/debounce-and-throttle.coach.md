## Reference approach

**Debounce.** Hold a timer handle. On each call, clear the existing timer and
set a new one for `delay` that invokes `fn` with the most recent arguments.
The whole implementation is three lines, and the difficulty is entirely in
knowing what it should do.

**Throttle, leading edge.** Hold the time of the last run. On each call, if
`now - last >= delay`, run immediately and record `now`; otherwise drop the call.

**Throttle, trailing edge.** Hold a timer and the latest arguments. If no timer
is pending, set one for the remaining time; when it fires, run with the stored
arguments. This is the version that does not lose the final call, and the one
most libraries mean when they say throttle with `trailing: true`.

Both are O(1) per call with one timer and a couple of fields of state.

The distinction worth drawing out: debounce is for "tell me when they have
stopped" — search-as-you-type, resize handlers, autosave. Throttle is for "do
this regularly but not constantly" — scroll position, progress reporting,
telemetry. A user who can give a concrete example of each has got the point of
the exercise; the code is almost incidental.

The subtlety the questions aim at is that leading-edge throttle *drops* calls,
and for a scroll handler that is fine, while for "save the user's last edit" it
silently loses data. Most production throttles therefore run both edges.

## Edge cases

- A single call, never repeated. Debounce runs it after `delay`. Leading-edge
  throttle runs it immediately; trailing-edge runs it after `delay`. If the user
  thinks those are equivalent, this is the case that separates them.
- Calls spaced exactly `delay` apart. The boundary, and `>` versus `>=` decides
  whether the second one runs.
- A burst, then silence. Does the final call ever reach `fn`? Leading-edge
  throttle: no. That is the data-loss case.
- Delay 0. Should still defer to the next tick rather than calling
  synchronously, or the wrapper changes the function's timing semantics.
- `fn` raising. Does the timer state get cleaned up, or is the wrapper now stuck
  believing something is pending forever?
- Calls that arrive while `fn` is running, if `fn` is slow or asynchronous.
- `this` / receiver binding, in languages where that is a thing. A wrapper that
  loses the receiver breaks on methods and works on free functions, so it passes
  every test written with free functions.
- Two wrapped copies of the same function, which must not share state.

## Common mistakes

- Implementing throttle and calling it debounce, or vice versa. Extremely
  common, and a test that only fires a burst cannot tell them apart: both run
  `fn` once. The distinguishing test is *when*, and the isolated single call.
- Not clearing the previous timer in debounce, so every call eventually fires
  and it becomes a delay rather than a debounce.
- Capturing the first call's arguments instead of the latest, so the autosave
  writes the first keystroke.
- Leading-edge throttle that drops the final call, shipped where trailing was
  needed. Not a bug in the code, a bug in the choice; worth naming as such.
- Comparing against the time of the last *call* rather than the last *run* in
  throttle, which makes a steady stream of calls starve `fn` entirely.
- Returning a stale value, or undefined, and having the caller depend on it. The
  honest answer is that a deferred function cannot return synchronously, which
  is why real debounce wrappers return nothing or a promise.
- Storing the timer in a shared or module-level variable, so two wrapped
  functions interfere.

## Hint ladder

1. Draw a timeline for the first worked example, calls at 0, 50 and 90 with a
   delay of 100. Mark where debounce runs and where throttle runs. Now draw the
   timeline for one single call at 0. What changed for each?
2. One of these needs to *cancel* something it set earlier. The other needs to
   *remember* when something last happened. Which is which tells you what state
   each one holds.
3. Solve a smaller problem first: write debounce only, and test it with calls at
   0 and 50 asserting `fn` ran exactly once and at 150. Get the cancel right
   before touching throttle.
4. ```
   debounce(fn, delay):
       timer = null
       return (...args) =>
           # one line here, and it is about the OLD timer
           timer = setTimeout(() => fn(...args), delay)

   throttle(fn, delay):
       last = -infinity
       return (...args) =>
           if  # a comparison involving now, last and delay
               last = now; fn(...args)
           # and think hard about whether this path should be empty
   ```

## What to notice (predict-then-compare)

- Could the user's two sentences be swapped? If yes, the difference is not yet
  understood, and the code will be right by accident.
- Did the plan mention cancelling in debounce? Without it the behavior is a
  delay, and the bug is invisible under a burst-only test.
- Which arguments did the plan say reach `fn`? "The last ones" is usually right
  and is almost never stated unprompted.
- Did the plan notice that leading-edge throttle loses the final call? That is
  the production-incident version of this exercise.
