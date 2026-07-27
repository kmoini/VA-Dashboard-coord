---
name: activity-log-entity-type-trap
description: Writing an activity_logs row with an entity_type not in the Postgres CHECK allow-list silently rolls back the whole transaction and surfaces as an unrelated field error; sqlite dev never catches it.
metadata: 
  node_type: memory
  type: project
  originSessionId: 29ebd79e-444d-46cc-a8fb-0a0e32bc2386
  modified: 2026-07-27T16:09:53.104Z
---

`activity_logs` has two Postgres CHECK constraints, `chk_activity_logs_entity_type`
and `chk_activity_logs_action`. Each new migration **redefines the entire allow-list**,
so the last-run migration wins (currently `2026_06_18_000007_add_intelligence_actions_to_activity_logs`).
Passing an `entity_type` (or `action`) string that is not in that list makes the INSERT
fail. Because `ActivityLogService::log()` is normally called as the last step *inside* a
`DB::transaction`, the violation rolls back **all preceding work** (the user, the client,
everything), and whatever `catch` wraps it reports a misleading, unrelated error.

Confirmed twice:
- 2026-06 — `migrate --force` failed on prod because `ClientMessage` was missing (fixed in da12194).
- 2026-07-10 — `ReferralController::accept()` logged `entity_type='ReferralAccepted'`
  (never an allowed value). Every client onboarding via `/refer/{token}` rolled back and
  showed "the email may already be in use" on *any* email. Fixed in checkpoint-124 by
  using `'ReferralToken'`, the already-allowed value matching the logged `entity_id`.

- 2026-07-24/25 (third time, PROD, found by Shahab while migrating prod) — the Books branch
  merged out of order, so `2026_07_13_000003_add_document_folder_to_activity_logs` rebuilt
  `chk_activity_logs_entity_type` from a hardcoded list that has `QuickBooksConnection`/
  `QuickBooksInvoice` but NO `BooksInvoice`/`BooksBill`/`BooksPayment` (verified in that file).
  Since that deploy, prod had been REJECTING every Books activity-log write, rolling back the
  whole Books transaction. Fix is `2026_07_24_000002_add_ai_prompt_to_activity_logs`, which
  stops hardcoding: it reads the LIVE allow-list, unions it with a BASELINE (Books entities
  included) plus `AiPrompt`, so it cannot drift again. On prod, `2026_07_06_{000001,000004,000007}`
  are marked already-run (their end state is covered) and the rest of `migrate` runs; Shahab
  has the runbook. **This is the argument for never hardcoding the list in a new migration.**

**Sibling constraint — `chk_activity_logs_user_or_ai`** (same roll-back family): requires
`(user_id NOT NULL AND action_source NOT IN ('ai_worker','stripe_webhook'))` OR
`(user_id NULL AND action_source IN ('ai_worker','stripe_webhook'))`. Any background/no-auth
write (mobile sync, email intake, queue jobs) has `user_id=null`, so it MUST set
`action_source='ai_worker'` or the whole INSERT rolls back. 2026-07-10: `TransactionObserver::created`
only tagged `ai_worker` when `source==='ai'`; mobile-synced txns (`source='client'`, no auth)
fell through to `web_dashboard`+null user → constraint violation → `Transaction::create` rolled
back → mobile transactions silently never reached Record Keeping. Fixed (commit 7dd4014) by
`($tx->source==='ai' || !auth()->check()) ? 'ai_worker' : null` — mirroring the `updated()` hook.
When creating a Transaction in ANY no-auth path, expect this. Related: [[mobile-poll-queue-fix]].

**Why:** dev runs sqlite, and every one of these migrations early-returns on sqlite
(`if (DB::getDriverName() === 'sqlite') return;`). CHECK constraints therefore do not
exist locally, so this class of bug is invisible until it hits prod Postgres.

**How to apply:**
- `entity_type` names the **entity** the `entity_id` points at (`ReferralToken`), never an
  event name (`ReferralAccepted`). Match the two.
- Before using a new `entity_type`/`action` string, grep the latest
  `*_activity_logs*` migration for the current allow-list. Add a migration if it is genuinely new.
- Never let a `catch` around a transaction attribute a failure to a specific form field it
  cannot actually verify. Return a general error instead, or the real bug stays hidden.
- Suspect this whenever a prod-only write "always fails" while dev is green.

Related: [[colleague-branch-integration-2026-06]], [[checkpoint-rule]], [[deploy-process]]
