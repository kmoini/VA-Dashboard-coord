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

## 6. 2026-10-27: the policy questions are ANSWERED
The team answered Q2 to Q12 of the 15 (plus P1, P6, P12 and the vocabulary A/B/C/D) on 2026-10-27: see docs/ACCOUNTING-V2-TEAM-ANSWERS-2026-10-27.md (branch work/team-answers-20261027) and [[ar-accountant-workflow-questions]]. Q1 (duplicate invoice) and Q13/Q14/Q15 of the 2026-10-15 list were not re-asked (current behaviour stands: Q15 = kept out of the books; Q13 = see Q9; Q14 = see Q10). Engineering list to resume after the five waiting checkpoints, in the doc's order: Q7+Q11 blocking, Q3 exact-only auto-link, Q6 rule yields to anomaly, Q2 30-day window, Q5/Q8 thresholds, Q4 credit notes, Q12c split, vocabulary.
2026-10-27 22:30Z: item 1 MERGED as cp-359 = aa1b7ab (2026-10-28 01:05Z, gate GREEN 4a380467), NOT deployed yet: Q7 ACCOUNT_SIDE_MISMATCH + Q11 INTERCOMPANY block posting. Next in order: Q3 exact-only auto-link, Q6 rule yields to anomaly, Q2 30-day window, Q5/Q8 thresholds (1,000 / 500), Q4 credit notes, Q12c split, vocabulary.
2026-10-27 23:40Z: item 2 MERGED as cp-360 = 05bd0b8 (2026-10-28 01:15Z, gate GREEN e09fd1b1), NOT deployed yet: Q3 exact-only auto-link for APPROVED payments ( finding: approval locks every dimension, so approved payments were never relinked before; now exact -> linked + decision record, else `settlement_proposals` modifier + SETTLEMENT_AMBIGUOUS note, approval untouched; pending payments unchanged). Next: Q6 rule yields to anomaly, Q2 30-day window, Q5/Q8 thresholds, Q4 credit notes, Q12c split, vocabulary.
2026-10-28 01:30Z: item 3 MERGED as cp-361 = 4957061 (2026-10-28 02:30Z, gate GREEN df4826e3), NOT deployed yet: Q6 RuleYieldsToAnomaly: a learned rule / pattern / firm mapping / past-books account is set aside into account_rule_set_aside + first candidate and ACCOUNT_AMBIGUITY asks when AMOUNT_ANOMALY, ASSET_PURCHASE or CAPITAL_VS_EXPENSE is on the row. Next: Q2 30-day awaiting-invoice window, Q5/Q8 thresholds (1,000 / 500), Q4 credit notes, Q12c split, vocabulary. Local PostgreSQL (Laragon) died once on 2026-10-27 night; restart with pg_ctl start -D /c/laragon/data/postgresql.
2026-10-28 02:20Z: item 4 BUILT: Q2 awaiting-invoice window (work/team-answers-q2-20261028 = validation/..., cp-362 candidate; MIGRATION 2026_10_28_000001 awaiting_invoice_days + JSX profile field 11 = npm run build; nightly v2:expire-awaiting-invoices 02:00; NO_INVOICE_AFTER_WINDOW advisory; a later same-amount bill = DUPLICATE_SUSPECTED naming the expensed entry; large-amount notice >= 5,000). Next: Q5/Q8 thresholds (1,000 / 500), Q4 credit notes, Q12c split, vocabulary.
