---
name: books-phase3-production-deploy
description: "Books/Bigcapital Phase 3 (void, Quick Expense, mini P&L chart, full payment collection) shipped to production 2026-07-03, bundled with Amin's unreleased AI Assistant + Record Keeping redesign"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1a584622-f8f2-4360-ad80-271f755bae42
---

Books Phase 3 (void invoice/bill, Quick Expense entry, mini P&L bar chart on Overview,
invoice/bill creation with proper document numbering, and full payment collection —
Receive Payment + Pay Bill) is **live on production** (`my.voiceaccountant.com`) as of
2026-07-03, commit `520d356` on both `main` and `dev`.

**Why deployed without the usual "Amin tests first" gate:** the feature was tested
end-to-end across 7 rounds of live browser testing on `pr.voiceaccountant.com` (via
Claude web + computer use, using `ZZTEST-*`-prefixed fixtures against the real Bigcapital
API — not mocks) before Kamyar made the explicit call to proceed straight to production.
Ten real bugs were found and fixed this way (BUG-B01 through B10 in `docs/bugs.md`),
several only reproducible against the live Bigcapital API. See [[checkpoint-rule]] and
[[wait-for-user-test-before-deploy]] for the general rule this was a deliberate,
user-authorized exception to — not a precedent to assume applies elsewhere.

**Bundled in the same merge (dev had two other "shipped, NOT deployed" features sitting
on it):**
- Amin's Per-transaction AI Assistant (checkpoints 064/065)
- Amin's Record Keeping redesign (checkpoints 057-062) — **still needs its own manual
  prod steps that the deploy webhook does NOT do**: `php artisan migrate --force` +
  a paid `GEMINI_API_KEY` in prod `.env` + `php artisan config:clear`. Amin was notified
  via the coord inbox (`inbox_amin.md`, 2026-07-03) but had not yet confirmed those steps
  ran as of this writing — check with him before assuming Record Keeping actually works
  on prod.

**How to apply:** before touching Books/Bigcapital write paths (invoices, bills,
payments, items, expenses), read `docs/bugs.md`'s "Books / Bigcapital Integration"
section and rules R-21 through R-26 — it documents real, non-obvious Bigcapital API
requirements discovered live (document-number fields required per endpoint, `open`/
`delivered` lifecycle flags needed before a document is payable, `Inertia::optional()`
props going stale after any validation error). Don't re-derive these by trial and error.

**One known minor cosmetic issue, not chased further:** a freshly-created invoice's
detail drawer briefly shows "No line items available" (Balance is still correct),
self-resolving once paid — likely Bigcapital read-after-write lag, not a code bug.

**Also caught during the `dev`→`main` merge:** a prior perf commit
(`f27e462`, "instant page navigation") had converted all 50 Inertia pages — including
Books — to the persistent-layout pattern (`Page.layout = page => <AuthenticatedLayout>{page}</AuthenticatedLayout>`
+ plain `function` instead of `export default function`). The first conflict-resolution
instinct during the merge would have silently reverted that for Books specifically —
worth double-checking this pattern is intact if Books/Index.jsx gets touched again and a
merge conflict shows up in its function declaration.
