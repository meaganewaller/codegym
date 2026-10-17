---
name: decision-record
description: Write the next numbered decision record in docs/decisions/. Use when the user wants to record a decision, write an ADR, or capture why something was chosen.
argument-hint: "[the decision]"
---

Write a short decision record for: $ARGUMENTS

Records live in `docs/decisions/` as `NNNN-kebab-title.md`.

## Steps

1. List `docs/decisions/` and take the highest number plus one, zero-padded to four digits.
2. Get today's date from `date +%F`. Don't guess it.
3. Ask at most two questions, and only for what you can't infer: what was decided, and what the alternatives were. If the conversation already says, don't ask.
4. Write the file with this shape and keep it to about a page:

```markdown
# NNNN. Title

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Revisit:** a date, or a condition that should trigger a second look

## Context
Why this came up and what constrains it. Facts only.

## Decision
What we are doing, in one or two paragraphs.

## Alternatives considered
Each real alternative and the reason it lost.

## Consequences
**Good**: ...
**Bad**: ...
```

## Rules

- Never rewrite an accepted record. If a decision changes, write a new one, set the old one's status to `Superseded by NNNN`, and link both ways. That status line is the only edit allowed to an old record.
- Rails main bumps do not get their own record. They go in the bump log in `0001-run-on-rails-main.md`.
- Write what was decided and why, not a pitch for it. Include the downsides.
