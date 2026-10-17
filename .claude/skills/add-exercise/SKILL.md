---
name: add-exercise
description: Author a new codegym exercise in the house format, including the hidden coach notes. Use when the user wants to add, draft, write, or schedule an exercise.
argument-hint: "[idea or topic]"
---

Exercises are Markdown files in `db/exercises/`. Each one has two files:

- `db/exercises/<slug>.md`: what the user sees. Front matter plus the problem.
- `db/exercises/<slug>.coach.md`: material only the coach sees. It must never be rendered on a page or included in any user-facing query.

If `db/exercises/` or the loader in `db/seeds.rb` doesn't exist yet, say so and ask before creating them.

## What makes a good exercise

- It can be done unaided in the stated time (default 30 minutes; 45 for hard ones).
- It has a real design choice, not a trick. Someone should be able to approach it two reasonable ways and compare.
- It is language-agnostic unless the topic is a specific language.
- It works the skills agents wear down: decomposing a vague problem, debugging unfamiliar code, finding a planted bug in a diff, predicting what code does before running it. Classic algorithms are fine but shouldn't be most of the library.

Reuse an existing `topic` where one fits (`algorithms`, `data-structures`, `parsing`, `systems`, `async`) and add a new one only with a reason.

## `<slug>.md`

```markdown
---
slug: kebab-case-name
title: Short title
summary: One sentence for the library card.
difficulty: easy        # easy | medium | hard
topic: algorithms
minutes: 30
published_at: 2026-11-02 00:00:00   # UTC; a future date keeps it hidden until then
---

## The problem
What to build, with two or three input/output examples.

## Before you code
Questions that force a written plan: edge cases, data structures, the decision to make now.

## Stretch
One harder variation.
```

## `<slug>.coach.md`

```markdown
## Reference approach
One good solution in words, plus its complexity. Name the alternative and its trade-off.

## Edge cases
The cases people miss, each with an input that triggers it.

## Common mistakes
What goes wrong and what it looks like.

## Hint ladder
1. A question that points at the problem.
2. The concept to look at.
3. A smaller subproblem to solve first.
4. A sketch of at most five lines with the key part left out.

## What to notice (predict-then-compare)
Two or three things to compare between the user's plan and the reference.
```

## Before finishing

- Work the problem yourself from the statement alone. If the examples are ambiguous or the time is unrealistic, fix the problem, not the time.
- Check that the `Before you code` questions don't give away the reference approach.
- Confirm `published_at` is what the owner wants. Default to a future date so nothing goes live by accident.
