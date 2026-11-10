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

**2026-11-07 (cp-441, 7e5a2fe6, committed locally, tag+push+deploy handed to
Amin):** prod showed the ••3922 fee line "No entry yet" although the read
produced the fee row: `DuplicateMatcherV2` had folded it into the ••1234
statement's fee entry (tx 2380, three files on one row) and line 26 of
import 11 held that entry. Rule: a "statement"-kind row is NOT a duplicate
of a "statement" row already CLAIMED by a bank line of another file
(checksum differs); unclaimed charges still fold; same bytes always fold.
Ingest passes `extras.source_attachment_ids`. ⚠️ First version ("different
bytes = different charge") broke MultiTransactionDocumentTest re-upload
(harness gives random checksums), hence the narrower claim-based rule.
⚠️ Local Laragon PG was DOWN mid-session; `pg_ctl` started from the Bash
tool dies with the task, start it detached via PowerShell Start-Process.

**2026-11-07 cp-441 LIVE (7e5a2fe6); cp-442 (901651ff) committed locally,
tag+push+deploy handed to Amin:** Amin re-uploaded the ••3922 file after
cp-441 and the fee was still folded: the same-bytes replay skipped the
claim test (`! $identicalDocument`). Dropped that condition; the claim
(claiming line's file checksum vs ours) already tells own statement from
another. Test `test_re_uploading_the_statement_that_lost_its_fee_...`.
After the deploy: upload the ••3922 file once more → fee books + auto-ticks.

**2026-11-07 cp-442 LIVE (901651ff). cp-443 (f9331002) committed locally,
tag+push+deploy handed to Amin:** the accounting team's round. Create entry
takes the account's company (was hidden by the company filter); confirm
clears DUPLICATE_SUSPECTED + funding flags; prompts now read the bank's
CREDITS too (interest, fee refunds) via migration 2026_11_07_000001 + guard
hashes re-pinned (⚠️ run `ai:extraction-check --runs=3` on the server);
"Not in QuickBooks" badge + per-row Push / Approve and push + "Push the
approved ones" / "Approve and push all" (POST /bank-reconciliation/{import}/push,
approve only when asked, same PushGate/router/job as the Push button);
"Open in QuickBooks" via QuickBooksService::entityDeepLink; opening balance
checked against the previous statement's closing + period gap (continuity).
NEXT (agreed order): cp-444/445 QBO mirror (source quickbooks, backfill via
History phase 2 reader, incremental via CDC watcher, migration for the
source CHECK); then edit/delete guard + discrepancy flag on reconciled
entries, report snapshot at finalize, adjustment entry, card-balance payment
offer. QB Desktop handoff lives in C:\Users\Amin\Downloads\BR QB\
QuickBooks-Reconciliation-Handoff (reverse-engineered; behaviour only, no
code/text copied; keep internal).
ai:extraction-check after the 2026-11-07 prompt change (bank credits): 18/18, category 15/15, GIFI 18/18, date 6/6.

**2026-11-07 cp-444 (dc189a6c) committed locally, tag+push+deploy handed to
Amin:** "Push the approved ones does nothing" after Approve and push all
queued 3 entries: presenter counted non-pushed as Not in QuickBooks and the
endpoint skipped queued silently. Now `BankLinePresenter::syncsFor` reads
the latest sync row of ANY status (pushed first); entry has sync_status +
sync_error; queued shown "Sending to QuickBooks…", error/needs_mapping/
skipped/conflict/deleted_remotely show the reason; counts: not_in_quickbooks
(excl. queued), queued_for_quickbooks, pushable. ⚠️ Asked Amin for the
transaction_integration_syncs rows of the last 6h + failed_jobs count to see
whether the worker actually sent the 3 (PushTransactionJob) or refused.

**2026-11-07 cp-445 (f2881671) committed locally, tag+push+deploy handed to
Amin:** the QuickBooks MIRROR. `QuickBooksRegisterMirror` reads the account's
register for the statement period from the GL report (`QboHistoryReader::lines`,
new; converter got `lines()` + account_id/id per line) and creates read-only
rows (source=quickbooks, approved, confirmed, qb_sync_status pushed, a pushed
TransactionIntegrationSync with the QBO type+id → never pushed back, deep
link works, matcher pairs them). Account pick auto by last4/name, else the
amber bar asks once (client_bank_accounts.qbo_account_id/name). Read on open
sitting when never read or >24h (bank_statement_imports.qbo_register_read_at/
error), "Read QuickBooks again". TransactionPolicy::update refuses source
quickbooks. transactionSource.js has a QuickBooks badge. "Map account for GIFI
N and push" on needs_mapping rows → /recordkeeping/{id}/map-and-push.
⚠️ QboAccountSnapshotService is FINAL: seed QboAccountSnapshot rows in tests
(last_seen_at now) instead of mocking. ⚠️ CHEQUE lines vs a payee-named entry
score 0.83 → proposed, not auto. Migration 2026_11_07_000002 widens the
transactions.source CHECK (pgsql) → prod needs migrate --force.
Not yet: CDC feed between sittings, backfill outside statements.

**2026-11-07 cp-445 LIVE; cp-446 (5cedc3ab) committed locally, tag+push+deploy
handed to Amin:** first prod read of the mirror worked (sandbox company CA
f148; ••3922 auto-named "10100 · TD-Chequing 0621-5213922"), but the Bank
Deposit Amin typed in QBO came back from the GL with 2,350 in the CREDIT
column → mirrored as an expense to vendor "S Ahmadi" → the money-in bank line
could not take it. Fix: `directionFor(type)` decides for Deposit/Sales
Receipt/Payment (in) and Expense/Check/Bill Payment/Refund Receipt (out),
sign only for Transfer/Journal/card credits; `refresh()` updates a mirrored
row on later reads (QBO owns it). ⚠️ QBO's Canadian locale shows DD/MM/YYYY:
Amin's "Oct 18" Canadian Tire expense was 18/09 = September, outside the
period, hence not mirrored (not a bug).

**2026-11-07 cp-446 LIVE and verified on prod** (Read QuickBooks again → the
deposit row corrected to revenue/customer and auto-matched; Canadian Tire
re-dated to Oct mirrored; ZOOM Map account and push → queued → QuickBooks).
**cp-447 (13722f63) committed locally, tag+push+deploy handed to Amin:**
"Failed to fetch" = the GL read ran inside the web request; now
`MirrorQuickBooksRegisterJob` (default queue, ⚠️ a static named `queue()` on a
job collides with Laravel's Dispatcher hook → named `queueRead()`), cache
marker `bank-reconciliation:qbo-mirror:{import}`, page polls every 4s while
`quickbooks.reading`. Record Keeping hides "Deleted there? Resend" for source
quickbooks; `QuickBooksDeletionWatcher::markDeleted` deletes a mirrored row
and unmatches its lines. Map picker filtered by entry type (expense-type /
income-type accounts). Open question: "�" in QBO account names (sandbox data
or snapshot encoding) — not investigated yet.
**cp-447 LIVE 2026-11-09 (13722f63).**
**cp-448 (4254d482) committed locally:** row "..." menu was clipped by the table's overflow-x container (only the first item showed on the last rows); now position:fixed from the button rect, opens upward near the bottom, closes on scroll/resize.

**2026-11-09:** full sitting finalized on prod (12/12, R badges, 0 open). One
entry (tx 2397, R Martin) stayed out of QBO: BANK_TRANSFER via the team's
phase 6 rule (BusinessEventResolver ~L471: money in reading like a transfer
from an unknown party is HELD, TRANSFER_SOURCE_UNVERIFIED) → mapper wants the
source account. ⚠️ There was NO way to change the event in the UI (Kind =
document_type; mapping GIFI does nothing). Rule kept; cp-449 (1e7808fd) adds
the answer: event picker + POST /recordkeeping/{id}/event (TransactionsController
::setEvent). ⚠️ local PG died again mid-run; restart with PowerShell
Start-Process pg_ctl -w and poll pg_isready.
**cp-450 (c6746156):** confirm box before an event change; '�' = U+FFFD in QBO's own raw Name (chart moved from Desktop) → display via existing AccountNameNormalizer::forDisplay (already used since BBMS 2026-10-20) wired into the new screens. Remaining: CDC feed between sittings, reconciled-entry edit guard, Finalize report PDF/CSV.

- cp-452 COMMITTED 2026-11-09 (7df1d5de, not tagged yet): QuickBooks feed between sittings. `quickbooks:mirror-registers` twiceDaily(6,13); reads only clients with one QBO company and a bank account with qbo_account_id; window = start of last month..today (2 GL reads/company/run); shares QuickBooksRegisterMirror::applyRegister with the sitting; new rows call BankLineMatcher::suggestForTransaction; reconciled mirrored row changed later gets metadata.quickbooks.changed_after_reconcile. Next free 453; next = reconciled-entry edit guard + discrepancy flag on page, Finalize report PDF/CSV.
- cp-452 LIVE 2026-11-09: server pulled with `git pull --no-tags --ff-only origin main` (webhook had not pulled); first run: Connection 12, 1 account, 0 new (2 reads).
- cp-452 VERIFIED on prod 2026-11-09 by Amin: new (1 new), edit (1 changed), re-run (0/0), delete (row gone within minutes via watch-deletions). Feed loop CLOSED.
- cp-453 COMMITTED 2026-11-09 (e5c43722, not tagged yet): reconciled-entry change warning. Finalize writes metadata.reconciled {import_id, amount, account_id}; ReconciledEntryCheck (computed) gives deleted/amount/account for FINALIZED statements only; R! on recon line + banner (counts.changed_since_finalized) + rail (statements[].changed); Record Keeping row prop `reconcile` + R! pill + detail banner + confirm box (resources/js/lib/reconciled.js) before amount/kind/bank account change + note in delete box. Never blocks. Next free 454; next = Finalize report PDF/CSV.
- cp-453 LIVE 2026-11-09 (server pulled + npm build by hand); awaiting Amin prod test.
- cp-453 VERIFIED on prod by Amin 2026-11-09 (banner, R!, confirm). cp-454 COMMITTED (c3f6742f): confirm is now ConfirmDialog tone="warning" via resources/js/lib/reconciled.jsx (promise, createRoot), inline edit guarded by confirmingRef. Next free 455.
- cp-454 LIVE 2026-11-09 (pulled + built by hand).
