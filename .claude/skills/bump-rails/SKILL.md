---
name: bump-rails
description: Run the weekly Rails main bump for codegym end to end. Use when the user asks to bump, update, or move Rails forward, or when it's time for the weekly update.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git log *) Bash(bundle info *)
---

Follow `docs/decisions/0001-run-on-rails-main.md`. A bump is one commit that changes only the Rails SHA.

## Steps

1. **Check the tree.** `git status` must be clean. If it isn't, stop and tell the owner; the script refuses a dirty tree anyway.
2. **Run `bin/bump-rails`.** It prints the old and new SHA and a GitHub compare link, then runs `bin/ci`. It will ask for permission because it changes the lockfile and commits.
3. **If CI is green and it committed:**
   - Read the commits between the two SHAs (`git log` inside the Rails checkout from `bundle info rails --path`, or the compare link). Summarize only what could touch this app: Active Record, Action View, Active Job and Solid Queue, Active Storage, generators and app templates, deprecations, and anything that changes defaults.
   - Say whether `bin/rails app:update` is worth running. Do not run it yourself: it is interactive and rewrites config files, so let the owner review each diff.
   - Add a row to the bump log in the ADR: date, `from` and `to` SHAs (10 characters), what changed for us, and the lesson. Leave the lesson blank if there isn't one; don't invent it.
4. **If CI failed:** nothing was committed and the change sits in the working tree.
   - Read the failing output and decide whether the cause is Rails, a gem that lags main, or our code.
   - If it's Rails, find the commit in the range that caused it, reduce it to a minimal reproduction, and show the owner. Rule 5 of the ADR applies: upstream before any local workaround. Do not pin stable or patch Rails without asking.
   - Add a bump log row for the failed attempt either way. Remind the owner that a week of red CI counts toward the escape-hatch triggers.

## Report

Finish with: the SHA range, whether CI passed, the two or three changes that matter to this app, and what the owner should do next.
