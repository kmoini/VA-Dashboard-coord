---
name: mobile-poll-queue-fix
description: "Mobile→dashboard transaction sync broke (poll on an unconsumed queue); fix made locally on dev, pending Amin's test + deploy"
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

Mobile-recorded client transactions stopped appearing in the accountant's Record Keeping list (a client's **income** never synced; only an older expense showed). **Root cause:** `PollMobileChangesJob` was dispatched to the **`mobile-sync`** queue, but the prod Supervisor worker AND a manual `php artisan queue:work` both run with **no `--queue`** → they drain **only `default`**. Nothing consumed `mobile-sync`, so the `/changes-since` poll never ran. (`queue:work` "doing nothing" was this exact blind spot.)

**Fix (made on `dev` 2026-06-27, backend-only):**
- `config/mobile.php` → `poll.queue` default `mobile-sync` → **`default`** (overridable via `MOBILE_POLL_QUEUE`, but only if you also run a worker for that queue).
- `MobileTransactionProjector::projectFirm()` self-heal: incremental query now ALSO picks up any **live mirror row with no `transactions` row** (anti-join on indexed `transactions.mobile_id`), so a row skipped once (e.g. Client not linked yet at projection time) is no longer stranded forever — it projects on the next poll.
- Full write-up: `docs/mobile-poll-queue-fix.md`.

**STATUS = NOT yet committed/pushed/deployed.** Waiting for Amin to test on prod first per [[wait-for-user-test-before-deploy]]. Immediate recovery (runs inline, bypasses the queue): `php artisan mobile:poll --sync --force` then `php artisan mobile:project-transactions`. After it works → commit + checkpoint + deploy ([[deploy-process]]: `git pull` + `php artisan config:clear` + `php artisan queue:restart`); ensure prod `.env` does NOT pin `MOBILE_POLL_QUEUE=mobile-sync`.

**Durable gotcha:** any queued job on a non-`default` queue silently never runs in prod (the worker has no `--queue`). Keep new jobs on `default`, or add a worker that consumes the queue.

**Coordination:** left **DQ-0016** for Mobile Claude in `E:/Projects/union-plan-coord/from-dashboard/QUESTIONS_FOR_MOBILE.md` — asks them to confirm income ships in `/changes-since` like expense and that direction is encoded as `classification=INCOME` (dashboard maps INCOME→revenue, else expense). See [[union-plan-coordination]].

Related: [[dashboard-build-status]], [[checkpoint-rule]].
