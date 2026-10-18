## Reference approach

Append one record per mutation to a log file, flush, then update the in-memory
map. On startup, read the log from the beginning and replay every record into
the map; the map is a cache of the log, and the log is the truth.

A record needs an operation, a key, and for `set` a value. The usual encodings
are one JSON object per line, or a length-prefixed binary record. Length
prefixing makes torn-write detection trivial: if fewer bytes remain than the
prefix promises, the record is incomplete. With line-delimited JSON, a record
that does not parse, or a final line with no newline, is the signal.

Replay is O(records), and the in-memory map makes reads O(1).

The thing this exercise exists to teach is the first question's answer. `write`
puts bytes in the operating system's page cache and returns; the data is not on
the disk and a power loss loses it, though a process kill does not. `fsync`
pushes it to the device and is one to two orders of magnitude slower. So:

- No flush at all: survives `kill -9`, loses data on power loss.
- `fsync` per write: survives power loss, and is slow enough that every real
  database offers a way to turn it off.
- Group commit — batch several operations into one `fsync` — is what real systems
  do, and it means acknowledging a write before it is durable *on purpose*.

A user who says "it is durable" without distinguishing these has not done the
exercise, even with working code. A user who says "I flush to the OS, so I
survive a crash but not a power cut, and here is why I chose that" has done it
completely, whatever their code looks like.

The alternative design is a copy-on-write snapshot: write the whole state to a
temp file and `rename` it over the old one, relying on rename being atomic. Much
simpler, no replay, and O(state) per write rather than O(1), so it is the right
answer for small state and hopeless for large. It is also exactly the stretch's
compaction step, so it is worth building anyway.

## Edge cases

- No log file at all on first start: an empty store, not an error.
- An empty log file, zero bytes.
- A torn final record. The *only* correct move is to discard it and treat it as
  never acknowledged, because the caller never got a reply.
- A torn record in the middle, which should not be possible with append-only
  writes, and is worth noticing as an invariant rather than a case to handle.
- Delete of a key that does not exist.
- Set, delete, then set the same key again. Replay order is everything, and a
  replay that applies deletes after sets, by grouping them, gets this wrong.
- A value that is an empty string, versus a deleted key, versus a key never set.
  Three different things, and a naive encoding collapses two of them.
- A value containing the record separator, or invalid UTF-8.
- A very large value.
- Opening the same log from two stores at once, which the design cannot support
  and should ideally refuse rather than corrupt.

## Common mistakes

- Updating memory before appending to the log. The window is tiny and it
  destroys the entire guarantee: a crash in between acknowledges an operation
  that is not in the log. The name "write-ahead" is the whole specification.
- Never flushing, then claiming crash safety. Partly right, and the useful
  question is which crash.
- `fsync` per write with no acknowledgement of the cost, which is a defensible
  choice presented as if it were free.
- Representing a delete by writing an empty value, so an empty string becomes
  indistinguishable from a deletion.
- Crashing on a torn final line rather than discarding it, so one unlucky kill
  makes the store permanently unopenable. The worst failure mode here, because
  it turns a recoverable crash into data loss.
- Replaying by building a map keyed on key and keeping only the last record seen
  per key, using a non-ordered traversal. Works by accident when the file is read
  in order and breaks when anything parallelizes it.
- Truncating or rewriting the log in place rather than appending, which gives up
  the one property append-only buys.
- Compaction that deletes the old log before the new one is durable and renamed,
  which loses everything on a crash in the gap. Nearly everyone writes this the
  first time.

## Hint ladder

1. Write down the exact sequence of steps `set("a", "1")` performs, numbered.
   Now, for each gap between two steps, ask: if the process dies here, what does
   the next startup see, and did the caller get a reply? One of those gaps is
   the dangerous one.
2. The dangerous gap is the one where memory has changed and the log has not.
   That decides the order of two operations, permanently, and gives the technique
   its name.
3. Solve a smaller problem first: handle only `set`, with no deletes and no
   flushing decisions. Write the log, kill the process with the hardest kill
   your system has, restart, and confirm the data is there. Only then decide
   what `set` is actually promising.
4. ```
   set(key, value):
       record = encode("set", key, value)
       append(record)          # step 1
       maybe_flush()           # step 2 -- and WHICH flush is the exercise
       memory[key] = value     # step 3
       return                  # what have you promised by now?

   recover():
       for record in read_records(log):
           # apply in order; and the LAST record may be a lie
   ```

## What to notice (predict-then-compare)

- Did the plan put the log append before the memory update, and say why? If the
  order is incidental rather than argued, the guarantee is accidental.
- Did the plan distinguish the page cache from the disk? This is the single idea
  worth carrying away, and it is the one agents most reliably paper over with
  the word "durable".
- Did the plan decide what recovery does with a torn final record *before*
  writing recovery? Discovering it later usually produces the crash-on-open bug.
- Did the plan notice that compaction introduces a new crash window rather than
  just saving space? Trading one failure mode for another is the recurring shape
  of systems work.
