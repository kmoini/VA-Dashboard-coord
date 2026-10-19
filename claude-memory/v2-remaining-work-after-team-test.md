---
name: v2-remaining-work-after-team-test
description: PARKED 2026-10-15 - the remaining V2 work list (owner + engineering + accounting decisions) saved before fixing the problems the accounting team found in their first sandbox test; Amin asked to be reminded to resume it
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-16T18:38:25.167Z
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
- After the S3 key: the command ALREADY EXISTS (`app/Console/Commands/MigrateLocalAttachmentsToS3.php`, verified 2026-10-17); run it, confirm with status.
- Auto-link a payment that was approved and pushed before its bill when the bill arrives (if policy answer 3 = automatic); today the accountant links on the row (settlement endpoint) then Re-sync applies it.
- Live proof of the remaining families on a sandbox: Deposit (non-sale money in), VendorCredit, RefundReceipt, multi-company client.
- ~~Stabilise the flaky storage-fake family on CI~~ ROOT-CAUSED + FIXED 2026-10-16 (`78027eb` on the stage-1 branch). Not storage at all: the attachment push writes its OWN sync row (provider_key `quickbooks:attachment:<id>`, status skipped "could not be read from storage" because the test file has no bytes) into the SAME `transaction_integration_syncs` table. Test helpers read `where transaction_id ... first()` with no filter and no order; SQLite = rowid order (always the tx row), Postgres = heap order (an UPDATED tx row can come after the attachment row). Fix = `where provider_key not like '%:attachment:%' orderBy id` in 7 test files (the filter the product code already uses). Rule: never read a sync row in a test without that filter.
- ~~Remove the old temporary prod routes~~ ALREADY REMOVED (routes/web.php carries only the removal comments; verified 2026-10-17).
- Mapper edge (firm mapping vs engine chart pick when the code was not derived from the account): implement per policy answer 10.

## 3. Reporting / release decision
- After the team test: results report (which scenarios passed LIVE on the team sandbox), update the test plan doc.
- Production readiness (G6) only when: S3 fixed, connections clean, policy answers implemented, team test passed without a stop rule.

**How to apply:** when Amin says the team-test problems are handled (or asks "what was left?"), bring this list back in priority order and strike what is already done.

## 4. Added 2026-10-16 night (Amin: "after the three learning stages, we continue these")
Learning stages A/B/C approved by Amin 2026-10-16 (A started that night on validation/v2-phase1-stage1-20261016). **When A, B and C are done, resume:** this list above (sections 1 to 3), PLUS: deploy of cp-303 (merge branch → main, tag, `php artisan migrate` for the prompt publish, `optimize:clear`, flags ACCOUNTING_V2_GIFI_CANDIDATES + ACCOUNTING_V2_ACCOUNT_NAME_AUTO_PICK on the server), the picker UI for the GIFI shortlist, the optional model ranking call on contested rows, the team's vocabulary decisions A to F (cleaning services/supplies, groceries, mixed receipts, printing, capitalization), the empty `date_as_printed` the model returns on 2 of 3 documents, the U+FFFD in chart snapshot names (QboAccountSnapshotService encoding), and the 15 policy questions.

## 5. 2026-10-17 evening: policy questions PARKED (weekend, no accountant access)
Amin: "وقتی جواب گرفتم بهت میگم". The 15 questions + A–F are in docs/ACCOUNTING-V2-POLICY-QUESTIONS-2026-10-15.md. Do NOT re-ask; resume when he brings answers. cp-304 live. Engineering not blocked on the team: remove temp prod routes, GifiLearningService vendor-token fix (GifiAssigner manual/portal paths still use the description-prefix token), write attachments:migrate-local-to-s3 ahead of the S3 key, harness 3-run measurement after phase 1, per-rule history on AI Preferences.
