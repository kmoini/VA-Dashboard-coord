---
name: v2-remaining-work-after-team-test
description: PARKED 2026-10-15 - the remaining V2 work list (owner + engineering + accounting decisions) saved before fixing the problems the accounting team found in their first sandbox test; Amin asked to be reminded to resume it
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-15T21:56:36.607Z
---

Context: production = checkpoint-302 (`8386aac`), merged and deployed 2026-10-14 night.
The accounting team ran their first sandbox test on 2026-10-15 and hit problems.
Amin: "first let's deal with those problems, then remind me to continue this list."
**Resume this list after the team-test problems are fixed.** [[accounting-v2-phase9-ci-gate-status]]

## 1. Owner (Amin)
- Send `php artisan accounting:v2-status` after test-client setup: every test connection `token = ok`, no tax-mapping warning, no auto_push ON.
- One sandbox company per test client; never reconnect clients 50/73 (kills 67's token); disconnect the laptop's local connection to realm 9341457870284884 (or keep the local stack closed).
- Collect the answers to the 15 policy questions (Persian list with options, given 2026-10-15).
- S3: put a WRITE-capable key in the server `.env` (never share it); 1,648 attachments sit on the server's local disk.
- Disconnect the dead sandbox connections (clients 50, 73) so status is clean.
- Realm 9341457268634337 (30 pushed orphans): run verify-pushed on it or declare the sandbox retired.
- Colleague's `stash@{0}` on the laptop checkout: find the owner; never dropped without approval.

## 2. Engineering (after the owner's inputs)
- Record the 15 policy answers in `docs/ACCOUNTING-V2-DECISIONS.md`; implement each one that differs from current behaviour (failing-first test, branch, CI, merge).
- Fix whatever the team's test found (same protocol).
- After the S3 key: write `attachments:migrate-local-to-s3` (moves the local-disk files, verifies, updates storage_bucket), run it, confirm with status.
- Auto-link a payment that was approved and pushed before its bill when the bill arrives (if policy answer 3 = automatic); today the accountant links on the row (settlement endpoint) then Re-sync applies it.
- Live proof of the remaining families on a sandbox: Deposit (non-sale money in), VendorCredit, RefundReceipt, multi-company client.
- Stabilise the flaky `EventPostingTest::test_end_to_end_ingest_pick_approve_push…` (storage fake read; failed once on CI, passed on re-run and 3x locally).
- Remove the old temporary prod routes recorded in memory: `/temp/s3-write-test`, `/testfilesize`, `/testfilecheck`, `/temp/s3-attachment-test`.
- Mapper edge (firm mapping vs engine chart pick when the code was not derived from the account): implement per policy answer 10.

## 3. Reporting / release decision
- After the team test: results report (which scenarios passed LIVE on the team sandbox), update the test plan doc.
- Production readiness (G6) only when: S3 fixed, connections clean, policy answers implemented, team test passed without a stop rule.

**How to apply:** when Amin says the team-test problems are handled (or asks "what was left?"), bring this list back in priority order and strike what is already done.
