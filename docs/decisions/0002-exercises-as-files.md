# 0002. Exercises as Files in db/exercises/

- **Status:** Accepted
- **Date:** 2026-10-17
- **Revisit:** When someone other than the owner needs to author an exercise, which in the current plan means organizations (Phase 5)

## Context

An exercise is `slug`, `title`, `summary`, `body_md`, `difficulty`, `topic`, `minutes`, `published_at`, plus coach-only material that must never reach a rendered page. The `exercises` table exists either way: it landed with the data model in `codegym-g70`. The open question was only where the *authored source* lives and how rows get there.

Two things already assumed files before this was written down. `CLAUDE.md` describes exercises as Markdown in `db/exercises/<slug>.md` with front matter, and the `/add-exercise` skill specifies both that file and a `<slug>.coach.md` beside it — including a guard that it should ask before creating `db/exercises/` or the loader if they do not exist. The schema and the format were worked out in a throwaway Workers/D1 prototype, so this is not a new idea being tried for the first time.

The constraint that decides it: for the whole of Phase 1 the only author is the owner. There is no second author to coordinate with, no untrusted input, and no need for anyone to edit content without a checkout.

## Decision

Exercises are authored as Markdown files under `db/exercises/`, two per exercise:

- `db/exercises/<slug>.md` — YAML front matter carrying the eight columns, then the problem body, which becomes `body_md`.
- `db/exercises/<slug>.coach.md` — reference approach, edge cases, common mistakes and the hint ladder. Never loaded into `exercises`, never rendered, never reachable from a user-facing query.

A loader in `db/seeds.rb` reads those files and upserts rows keyed on `slug`, so seeding is idempotent and `db:seed:replant` is safe to run repeatedly. `bin/ci` already runs `db:seed:replant` on every commit, which means a malformed exercise file breaks the build rather than being discovered in production.

The files are the source of truth. The table is a projection of them, and nothing in Phase 1 writes to `exercises` except the loader.

## Alternatives considered

**Rows edited through an admin screen.** Lost because it buys nothing yet and costs a lot now: an authoring UI, a Markdown preview, validation surfaces, and an answer to "who may edit" before there is a second person who can. It also puts content outside code review — exercise wording is the product, and reviewing a diff is how it gets better. Worst of all, coach-only material would live in the same database the app queries, where a single careless `select` leaks a solution. Keeping it in an unreferenced file makes that leak structurally hard rather than a thing to remember.

**Files with no database table, reading and parsing on request.** Rejected because `attempts` needs a foreign key to something, and the library needs filtering and sorting by difficulty and topic. Re-parsing the directory per request to support that is a worse database than the one already in the schema.

**Database as source of truth, with files exported for review.** Rejected as the same work as the admin screen plus an export path, and the generated files are then not what anyone edits, so review becomes advisory.

## Consequences

**Good**

- Authoring is a text editor and a pull request. Exercise wording gets reviewed like code.
- Coach material is isolated by construction. No query can reach a file that nothing loads.
- Seeding is idempotent and runs in CI, so broken front matter fails the build.
- Scheduled publishing needs no new machinery: `published_at` is a field in front matter and the `published` scope already honors it.
- This does not close the door. The loader is the seam: when organizations arrive, it becomes an importer and database-authored rows sit beside file-authored ones.

**Bad**

- Adding an exercise requires a checkout, a commit and a deploy. No publishing from a phone.
- Two sources of truth in tension the moment anything else writes to `exercises`. Nothing may, until the importer decision is made deliberately.
- Front matter is unvalidated until the loader validates it; the database check constraints are the real backstop, and a bad `difficulty` will surface as a seed failure rather than a form error.
- `body_md` stays trusted content, so the sanitization question is deferred rather than answered. `codegym-nmf` owns it, and it must be settled before any exercise content arrives from outside this repository.
