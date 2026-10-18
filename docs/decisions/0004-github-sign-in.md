# 0004. GitHub Sign-In with Database-Backed Sessions

- **Status:** Accepted
- **Date:** 2026-10-18
- **Revisit:** If a second sign-in method is ever wanted, or when organizations arrive and sessions need to carry a tenant

## Context

`users.github_id` has been the identity since the data model landed (decision in `codegym-g70`), so the only question was how someone proves they are that GitHub account, and what the app remembers afterwards.

Rails ships an authentication generator, but it builds a password flow: `email_address` and `password_digest`, a passwords controller, a reset mailer. The parts worth having are underneath that — a `Session` row, a `Current` attributes object, and a concern with resume/start/terminate.

The app has no deploy target yet, so this is development-only for now. A GitHub OAuth App allows exactly one callback URL, so production will need a second app registration rather than an edit to this one.

## Decision

**OmniAuth, not a hand-rolled flow.** The authorization-code exchange is simple enough to write, and the part that is easy to get wrong is not the exchange — it is the `state` parameter that ties the callback to the request that started it. OmniAuth generates and verifies it, and turns a mismatch into the same failure path as any other rejection.

**`omniauth-rails_csrf_protection`, and a POST-only request phase.** This is the load-bearing one. OmniAuth's request phase over GET is a login-CSRF vector: a third-party page can point a browser at `/auth/github` and sign the visitor into an account the attacker controls, after which anything the visitor does is in the attacker's account. The gem requires a valid authenticity token on the request phase, which is why the sign-in control is a `button_to` and not a link.

**No scopes at all.** `github_id`, `login`, `name` and `avatar_url` all come from the public profile, so the consent screen asks for nothing beyond it and a leaked token grants no more than a signed-out visitor already has. Email would need `user:email`, and nothing wants email yet.

**Sessions in the database, with an absolute expiry.** A row per session means a session can be revoked: delete it and the next request is signed out. A self-contained cookie cannot offer that. The cookie carries only the row id, signed, `httponly`, `same_site: :lax` — lax rather than strict because the callback arrives as a top-level GET from github.com and a strict cookie would not be sent.

Rails' generator leaves sessions immortal. `Session::MAX_AGE` is 30 days from creation, absolute rather than rolling, and `Session.active` is what the lookup uses, so an expired row is indistinguishable from a missing one.

**Identity is `github_id`, and the profile is refreshed on every sign-in.** A GitHub account can be renamed; the row follows it rather than forking into a second user, which also means attempts stay attached.

**A `next` parameter, filtered to a same-site relative path.** Anything that could be read as a host is dropped rather than corrected: `//evil.test` is protocol-relative, `/\evil.test` is the same trick with a backslash, and a value with CR or LF is a header-injection attempt. The fallback is the library.

## Alternatives considered

**Hand-rolling the OAuth2 flow.** Genuinely attractive for a project whose point is getting better at Rails, and about sixty lines. Lost on the `state` parameter: the flow is easy, the CSRF protection around it is the part that is quietly wrong in most hand-rolled versions, and login CSRF is not a bug that announces itself. The learning is still available by reading what OmniAuth does.

**Rails' `generate authentication` as-is.** Rejected because it is a password flow. Its session handling was taken; its `User`, passwords controller and mailer were not.

**A GitHub App rather than an OAuth App.** Better when repository permissions are needed. This is sign-in only, so an OAuth App is the simpler fit.

**A rolling session expiry.** Refreshing the clock on every request keeps active users signed in indefinitely, which is friendlier and means a stolen cookie never ages out while it is being used. Absolute expiry was chosen for now because it is simpler to reason about and 30 days is not onerous. Worth revisiting if signing in monthly becomes annoying.

**A random session token instead of the row id.** The cookie is signed, so the id cannot be forged without `secret_key_base`, which is the protection Rails' own generator relies on. A random token would additionally avoid putting a sequential id in a cookie. Kept the generator's approach for now; this is the first thing to change if session handling is ever hardened further.

## Consequences

**Good**

- Login CSRF, callback forgery and tampered state are handled by a library that is maintained and widely attacked, rather than by code written once here.
- Sessions can be revoked, listed, and aged out, because they are rows.
- The consent screen asks for the minimum, so a cautious user has little to weigh.
- A renamed GitHub account keeps its history.

**Bad**

- Four more gems, and OmniAuth middleware in the stack, for one provider.
- Development-only until a deploy target exists, and production will need a second OAuth App registration with its own credentials.
- Absolute expiry means signing in again every 30 days even for an active user.
- Sessions are never swept. The table grows until something deletes expired rows; `Session.active` keeps them from being honoured, but a cleanup job is still owed.
