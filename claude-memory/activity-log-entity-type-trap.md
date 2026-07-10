---
name: activity-log-entity-type-trap
description: Writing an activity_logs row with an entity_type not in the Postgres CHECK allow-list silently rolls back the whole transaction and surfaces as an unrelated field error; sqlite dev never catches it.
metadata: 
  node_type: memory
  type: project
  originSessionId: 29ebd79e-444d-46cc-a8fb-0a0e32bc2386
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
