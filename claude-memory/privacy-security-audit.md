---
name: privacy-security-audit
description: "Privacy/security/global-distribution audit (2026-08-15). Phases 0-4 DONE in docs/privacy-audit-2026-08/; 2 implementation waves shipped local (NOT deployed, NOT committed). ⚠️ published policy promises 30-day hard deletion the code never performs, and denies ad/analytics sharing the mobile app does. READ before deletion, retention, privacy policy, App Store/Play declarations or third-party disclosure work."
metadata: 
  node_type: memory
  type: project
  originSessionId: 90bfe97b-b3e5-43a8-b891-a51ede8ca5d6
  modified: 2026-08-15T21:35:16.197Z
---

Full audit of va-dashboard2 + marketing site, run 2026-08-15 against `main` @ `0e586c2`. Report lives in `va-dashboard2/docs/privacy-audit-2026-08/` (7 files, 00→06). Mobile/n8n code work DEFERRED by Amin until the mobile backend switches to this project.

**Owner decisions taken 2026-08-15 (do not re-litigate):** soft delete STAYS, data is not purged yet, and what/when to purge is an internal decision for later. `gemini_call_logs` is kept deliberately for internal use. Telescope is out of scope (Amin turns it off + wipes it later). The retention register in `02-retention-register.md` is the list to decide from; NOTHING is being deleted at this stage.

**Corrections to common assumptions, all verified in code:** QuickBooks IS a live integration (OAuth routes + push service + encrypted token store), not a future one. Anthropic is a configured fallback AI provider alongside Gemini. Twilio (OTP) coexists with Telnyx and sync2all. Apple receipt-validation endpoints are called from the dashboard, not only the mobile app. The mobile product runs on a SEPARATE MySQL database via n8n, reached both by n8n workflows and by Laravel controllers under the `n8n.strangler:{slug}` feature flags.

**Shipped locally, tested, NOT committed and NOT deployed** (2 waves, 20 tests in `tests/Feature/Privacy/`, zero regressions — the 7 failures in the AI/document suites and 6 in ProfileTest/QuickBooks are PRE-EXISTING, proven by stash-and-compare; `database/factories/` does not exist, which is why ProfileTest cannot run):
1. Third-party credential revocation on account closure AND on disconnect. New `connection_events` table (append-only lifecycle record: connect/disconnect/revoke dates, scopes, provider response code, counts only — NEVER a token, test-enforced). New `AccountClosureService` is the seam any future purge step hangs off. Microsoft records `not_supported` because Graph has no app-scoped delegated revocation; QuickBooks is only revoked when the LAST firm member closes, since the company belongs to the firm.
2. AI minimisation: Gemini Files API uploads now deleted after every SYNCHRONOUS call (⚠️ deliberately NOT in `SubmitDocumentBatchJob` — a batch file must outlive the request or polling breaks); assistant client roster relevance-filtered per turn instead of shipping up to 200 client names on every message.

Also done: `ADMIN_ANALYTICS_ORIGINS` default narrowed from `*` to an explicit list (CORS binds browsers only, so no server-to-server integration can break); `SESSION_SECURE_COOKIE` now derives from the `APP_URL` scheme; `docker/community/flarum.env` + two `setup-community*.ps1` scripts had REAL credentials tracked in this auto-pushing repo — untracked and switched to env reads, but **rotation is still owed** (the values are in git history). Amin ran `migrate` + `config:clear` on 2026-08-15.

**⚠️ The two blocking gaps, both about published claims rather than code:** `delete-account.html` says "Hard-deleted within 30 days" five times and `privacy.html` §5.3/§5.4 repeats it, while nothing hard-deletes and the mobile `s3_purge_queue` has no consumer in either repo. And `privacy.html` §6 states personal data is not shared with "advertisers, or user-analytics vendors" while the mobile app runs Firebase Analytics on behavioural events plus a Google Ads/TikTok/Meta attribution pipeline (`app/_layout.tsx:242`, `docs/ADS_ATTRIBUTION.md`). The ATT gating itself is implemented CORRECTLY (prompt precedes sink registration). Suggested accurate replacement wording that reveals no internals is in `03-user-facing-deletion-copy.md`.

Everything in rank 1 of the plan waits on ONE business+legal decision: which data is anonymised vs deleted vs archived when an account closes, given that a closing user's transactions are frequently the FIRM's records with their own retention duty.

Related: [[wait-for-user-test-before-deploy]], [[checkpoint-rule]], [[autocommit-leaks-secrets]], [[feature-test-handoff]], [[document-each-change]], [[growth-books-session-pact]]
