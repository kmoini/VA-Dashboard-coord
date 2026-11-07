---
name: bank-reconciliation-workspace
description: "Bank Reconciliation workspace (sidebar page /bank-reconciliation) LIVE on prod as checkpoint-437 (78a1e099, 2026-11-06); checkpoint-438 (5d32a845) LIVE 2026-11-06 (upload from the page, repeat uploads folded, set account, read again); checkpoint-439 (f315c866, page relaid as ONE table with two header groups) and checkpoint-440 (f140ca91, AUTO-CONFIRM at >=0.95 via BankLineConfirmer, 60-day pool, name bonus 0.25, statement bonus only within 2 days, View statement + view document via FileViewer/ReceiptViewer) both LIVE on prod 2026-11-07 (f140ca91); ⚠️ tag checkpoint-439 was created on f140ca91 (after the pull), not on f315c866, fix commands handed to Amin; prod retest with DownloadsVA-recon-test fixtures pending; test fixtures in C:SERSAMINDOWNLOADSVA-RECON-TEST (STATEMENT FOR REGISTERED ACCOUNT ��3922 + 5 RECEIPTS); slice 1 of 3 (page + sitting finalize/cancel/reopen + follow_up + reconciled_at); slice 2 = ask client + upload-with-line-hint; slice 3 = PDF/CSV report + push period to QBO. READ before any reconciliation / bank line / statement work."
metadata:
  node_type: memory
  type: project
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-06T20:13:34.776Z
---

Built 2026-11-06 after checkpoint-436 (next free = 437), in the MAIN checkout
E:/Projects/va-dashboard2 (not the AR worktree). Doc with the test guide:
`docs/BANK-RECONCILIATION-WORKSPACE-2026-11-06.md`. Supersedes the dead
Bigcapital Books/Banking reconciliation ([[bank-reconciliation-feature]]) and
builds on [[accounting-v2-phase2-5-bank-statements]].

**Owner's brief (2026-11-06, two QB screenshots):** sidebar item; on statement
upload two tables, bank lines left, Record Keeping entries right, ticked face
to face; unmatched line offers upload / create / ask; accountant follow-up
(call the bank) keeps the sitting resumable or cancellable; then QBO + export.

**Slice 1 (built):** `BankReconciliationWorkspaceController` (index Inertia
`BankReconciliation/Index`, show JSON, finalize, cancel, reopen, line-candidates);
the statement import IS the sitting (`bank_statement_imports.session_state`
open|finalized|cancelled, "waiting" derived from follow_up lines);
`bank_statement_lines.status` gained `follow_up` + `note` (BankLinesController
resolve action `follow_up`; matcher still proposes on parked lines);
`transactions.reconciled_at` + `reconciled_import_id` stamped on finalize,
cleared on reopen, green R in Record Keeping; finalize refuses open lines with
422 `can_force`, "Finalize anyway" records `forced: true` (never-overrule rule);
finalized statements refuse line edits until reopened; "In the books, not on
this statement" second table with "Pick a bank line". Shared
`BankLinePresenter`. Migration `2026_11_06_000001` (prod: migrate --force +
optimize:clear). Activity log uses existing values (entity BooksBankReconciliation,
actions locked/canceled/unlocked) to dodge the CHECK trap.
Tests: `tests/Feature/AccountingV2/BankReconciliationWorkspaceTest.php` (7),
green on SQLite and local PG (`va_gate_test_recon`, created 2026-11-06 for this
session). ⚠️ PG caught `source => 'manual'` (CHECK allows ai|client|accountant|email).

**Decided, not built:** slice 2 = ask the client from the row (Inbox message +
push, auto-closed by the matching upload) and upload with `bank_statement_line_id`
hint; slice 3 = reconciliation report PDF (DomPDF) + CSV, "push every unpushed
entry of this period" to QBO, AI explanation of unknown lines. ⚠️ Intuit has NO
reconciliation API (cleared status not writable, bank feed lines not sendable);
never promise "send the reconciliation to QBO".

**How to apply:** wait for Amin's test ([[wait-for-user-test-before-deploy]]),
then checkpoint-437 per [[checkpoint-rule]]. Keep per-line actions on the phase
2.5 endpoints; do not revive the Bigcapital controller.

**2026-11-06 evening, first prod look (BBMS) after cp-437 went live:** six
cards "Account not identified, ? → ?, 0/0, does not add up" and nowhere to
upload. Cause: the same file uploaded repeatedly stores an import with 0 new
lines (every line a fingerprint duplicate, `duplicate_count`), and the AI
read no last4 the registry knows. Fix = cp-438 (5d32a845): Upload statement
button (reuses `BatchUploadModal presentation="drawer"`), repeat uploads
folded in the rail, default = newest open statement WITH lines, Set account
endpoint `POST /bank-reconciliation/{import}/account`, Read again (phase
2.5 reread). ⚠️ PG sorts NULL first in DESC: order with
`CASE WHEN period_end IS NULL THEN 1 ELSE 0 END` first (caught by the local
PG run). ⚠️ `source` on transactions is CHECKed: ai|client|accountant|email.

**2026-11-07 (cp-440) auto-confirm decision:** owner saw "Looks like Amazon 100%"
rows that still needed a click and asked for them to be ticked. Now
`BankLineMatcher::AUTO_AT = 0.95` confirms by itself (both directions,
`match_source = auto`, Undo one click); follow_up lines are only proposed to.
Pool widened to 60 days (bill pre-authorized two weeks after its date);
⚠️ the "booked from this statement" bonus is now limited to ±2 days, because
with the wide pool a 24-day-off line took a fee's entry on that bonus alone
(StatementLinesTest identical-lines caught it). `BankLineConfirmer` is the
one place a line becomes MATCHED (human + auto).
