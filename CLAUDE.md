# codegym

A practice gym for programmers who work with agents every day. Users pick an exercise, do it **without an agent** against a timer, and log how it went. The long-term product is a **coach** that makes you do the thinking (plan review, a hint ladder that never skips to the answer, a debrief) and remembers your habits.

This repo is also how the owner is getting better at Rails. That shapes how to work here (next section).

## Status

Early. Phase 1 is the plain product: GitHub login, exercise library, exercise page with timer, attempt log, progress page. The coach, API tokens, and organizations come later, in that order. Don't build ahead of the current phase.

The schema and exercise format were worked out in a throwaway Workers/Hono prototype. This Rails app is the real implementation.

## How to work with me here

- The owner wants to get better at Rails, not just ship features. For anything non-trivial (models, auth, a new feature), offer once: you write it, or the owner writes it and you review with `/sparring`. Respect the answer and don't ask again.
- Explain Rails-main specifics when they come up. If you're unsure an API exists on main, check the gem source (`bundle info rails --path`) instead of recalling 8.1 from memory.
- Work in small steps. Add a test with every behavior change. Say what you ran and what it showed.

## Rails on main (read before touching the Gemfile)

Decision: `docs/decisions/0001-run-on-rails-main.md`. The short version:

- Rails tracks `rails/rails` `main` (8.2.0.alpha when the project started; Ruby >= 3.3.5). `Gemfile.lock` pins the exact SHA.
- Never run a bare `bundle update`. Move Rails only with `bin/bump-rails` (or `/bump-rails`), one bump per commit, and add a row to the bump log in the ADR.
- If main breaks something, do not pin stable, vendor a copy, or add a monkey patch on your own. Diagnose, reduce it to a minimal repro, and talk to the owner. The escape hatch and its triggers are in the ADR.
- Docs and training data lag main. Prefer the source, the edge guides, and the latest *This Week in Rails*.

## Commands

```sh
bin/setup                 # install deps, prepare the database
bin/rails server          # run the app
bin/rails test            # unit and integration tests
bin/rails test test/models/exercise_test.rb   # one file
bin/ci                    # the full local CI run; must be green before a commit
bin/rubocop               # style (rails-omakase)
bin/brakeman              # security scan
```

## Domain

- `users`: identity is `github_id` (unique). Logins can change, ids don't.
- `exercises`: `slug`, `title`, `summary`, `body_md`, `difficulty` (easy/medium/hard), `topic`, `minutes`, `published_at`. A future `published_at` means hidden: not in the library, 404 on its page. Scheduled publishing relies on this, so don't bypass it.
- `attempts`: one row per sitting, append-only. Retrying an exercise adds a row. `outcome` is solved/partial/stuck; `plan`, `stuck_on` and `learned` are free text.
- Exercises are authored as Markdown in `db/exercises/<slug>.md` with front matter (planned; see `/add-exercise`). Coach-only material lives in `<slug>.coach.md` and must never be rendered to a page.
- `body_md` is trusted content written by us. Sanitize it before the app ever accepts exercise content from anyone else (organizations).

## Conventions

- Hotwire-first and server-rendered: Turbo and Stimulus on importmap. No SPA, no JS build step.
- Minitest with fixtures (Rails default). Request tests for flows, system tests sparingly (the timer is one).
- Follow `rubocop-rails-omakase`. Don't fight the formatter.
- Store times in UTC. Streaks are computed in UTC for now; per-user time zones are a known later change.
- Never read or print `config/master.key`, `config/credentials/*.key`, or any `.env` file. They are denied in `.claude/settings.json`.
- Decisions that cost something to reverse get a short record in `docs/decisions/` (`/decision-record`). Framework bumps go in the bump log instead.

## Guardrails for the coach (when we get there)

- The coach must not leak solutions. Reference solutions and hints are stored apart from anything rendered to the user, and are revealed only through the hint ladder or after the user submits a plan.
- It should hold the user to the commitment they made up front ("no answer until I've submitted a plan"), and still defer to the user if they insist.
- Every coach session has a hard cost cap. LLM calls go through background jobs, never inline in a request.
- Coach behavior needs evals, not just unit tests: adversarial prompts like "just tell me" that must not produce the answer.

## Project skills (`.claude/skills/`)

- `/sparring`: coach mode. Critiques and hints, never edits files.
- `/bump-rails`: the weekly Rails bump, from the script to the bump-log row.
- `/add-exercise`: author a new exercise and its hidden coach notes.
- `/decision-record`: write the next numbered decision record.
