---
name: historical-context-audit-2026-10-19
description: "2026-10-19 read-only audit for business profile + historical accounting context; found an unapproved-push hole (AccountingController::pushTransaction), client-scoped learning leak, QBO lock-catch bug; settlement rule c023522 kept unshipped"
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-19T21:05:46.685Z
---

Read-only architecture audit delivered to Amin for the design AI on 2026-10-19 (files in Downloads: VoiceAccountant-Business-Profile-Design-Review-2026-10-19.md and VoiceAccountant-Historical-Context-Architecture-Audit-2026-10-19.md). Nothing built yet; waiting for the design AI and Amin to decide.

Verified holes, all present in main at 845cf25, none fixed:
- `AccountingController::pushTransaction` (route accounting.push) queues a QBO push for ANY firm row, approved or pending; the only send-time guard (`LedgerEntryDTO::holdReason`) needs FLAG_EVENT_POSTING and releases on CONFIRMED; `PushTransactionJob` never checks status=approved. pushAll / retryBlocked / recheckTransaction are weak too. Approval over blocking reasons does not record which reasons were overridden.
- `DecisionMemory` keys client_id + vendor_key (not client_company_id): learning leaks between companies of one client.
- `QuickBooksService::ensureValidToken` catches LockTimeoutException at L148 without importing it (catch never matches); invalid_grant never marks a connection dead; no 429 handling.

Other facts: no table stores historical (QBO or imported) transactions; every GL/journal importer targets Bigcapital; CDC watcher only flags deletions of our own pushes; `ROLE_IMPORT_ONLY` is defined but unused. The Axle Corp sample CSV is a QuickBooks DESKTOP Transaction Detail export (573 lines = 231 balanced transactions; Clr, Action, Last modified by columns).

Settlement prompt rule c023522: recommended to stay UNSHIPPED (global prompt, wrong for a manager that collects guest funds); replace with a structured settlement read + PHP reconciler + profile (phase 7).

**Why:** these gaps decide what can be built safely; history/profile-driven choices must not sit on the push hole.
**How to apply:** before any work on profile/history/learning, propose phase 0 first (push gate on every dispatch site + in the job, company-scoped memory, QBO token fixes). Do not deploy c023522 unless Amin says so. Related: [[accounting-v2-phase9-ci-gate-status]], [[never-overrule-the-accountant]].

Phase 0 verification (same day, VoiceAccountant-Phase0-Safety-Verification-2026-10-19.md in Downloads), verified line by line:
- accounting.recheck ALSO pushes never-pushed rows (RecheckPushedEntry::run L59-62); both accounting.push and accounting.recheck are reachable by PORTAL users (EnsureMinRoleLevelOrClient lets portal users through; ResolveTenant allows accounting.*); a cross-client push by id is inferred, needs a test.
- setAccount (L1792) resyncs an already pushed QBO entity under the update policy only; QuickBooksExportProvider::update has no hold check.
- QuickBooksPushTest::test_pending_transaction_is_not_pushed tests the DEPRECATED QuickBooksPushService (green while the live endpoint pushes pending rows).
- Memory leak mechanisms: recalled chosen_account_external_id is matched by qbo_account_id in the CURRENT company's snapshot (realm-local ids collide); funding replay accepts any of the client's bank accounts regardless of company.
- OAuth callback updateOrCreate(firm, realm) changes client_id but keeps client_company_id; one-connection-per-company is app-level only.

Phase 0a BUILT 2026-10-19 (not merged, not deployed): branch work/phase0a-push-safety-20261019 = validation/phase0a-push-safety-20261019, head 1554def (gate 3024290 + tests 1554def). App\Integrations\PushGate at every dispatch site and inside PushTransactionJob/ResyncTransactionJob; recordConfirmation stores overridden_reasons; legacy confirmations accepted while accounting_v2.push_gate_accept_legacy_confirmations=true. CI green: SQLite 2665 passed, PostgreSQL gate 2359 passed. Waiting for Amin's decision to merge/test; 0b (company memory) and 0c (QBO token) NOT started.

Phase 0b + 0c BUILT the same day on the same branch (not merged, not deployed): 0ccc4fe (company-scoped memory; always-on same-QuickBooks-company account recall and same-company funding; flag accounting_v2.company_scoped_memory default off; learned_rule_switches.client_company_id migration 2026_10_19_000002; accounting:memory-scope-report), f13ce6d (LockTimeoutException imported; invalid_grant -> reconnect_required_at/reconnect_reason migration 2026_10_19_000003 + QuickBooksReconnectRequired; callback clears client_company_id when the client changes), plus summary doc docs/PHASE0-SAFETY-SUMMARY-2026-10-19.md. CI green on f13ce6d: SQLite 2680, PostgreSQL 2374. Owner decisions pending: Accounting-page push refusal, legacy approvals setting, when to turn company scope on, DB unique index on client_company_id (needs prod duplicate count).

MERGED 2026-10-19 (Amin approved all 4 recommendations: Accounting-page refusal fine; legacy approvals stay accepted; company scope stays OFF until Amin sends `accounting:memory-scope-report` output; DB unique index waits for the prod duplicate count): main = origin/main = 95e782e = checkpoint-309, pushed from the laptop. Server pull/migrate/build PENDING until Amin pastes git log -1.

DEPLOYED 2026-10-19: checkpoint-309 (95e782e) live, both migrations ran; connection 2 (ae74) now marked needs-reconnect by the probe. Scope report: 0 learned decisions on every multi-company client (22, 50, 75, 87) -> recommended ACCOUNTING_V2_COMPANY_SCOPED_MEMORY=true now. Prod duplicate count 0 -> checkpoint-310 (26c07de, 2026-10-20) adds the partial unique index on quickbooks_connections.client_company_id; tagged+pushed from the laptop, server pull+migrate PENDING.

PHASE 0 CLOSED 2026-10-20: prod = main = 26c07de = checkpoint-310; all three Phase 0 migrations Ran (batches 106-107), index quickbooks_connections_client_company_unique present; ACCOUNTING_V2_COMPANY_SCOPED_MEMORY=true on prod .env. Note: the server had already pulled 26c07de and migrated before Amin's commands (webhook/deploy ran it). Open next: team's 15 policy answers, profile/history decision (design-AI reports), S3 key (1779 attachments on local disk), connection 12 HST_ON mapping, dead connection 2.

PHASE 1 BUILT 2026-10-20 (Amin: 'شروع کن', default period prior FY + current): branch work/phase1-history-import-20261020 = validation/phase1-history-import-20261020, head 9bc68eb (ae51098 history import + 9bc68eb warning flash whitelist fix). Accounting History page /history behind ACCOUNTING_V2_HISTORY_IMPORT (default off); QbdTransactionDetailParser + HistoryImportService; tables history_imports/_import_rows/_entries/_lines/_links (migration 2026_10_20_000002). Real Axle file: 231 txns, 0 warnings, 63/65 payments linked. CI green (SQLite 2698, PG 2384). NOT merged: waiting for Amin's go to merge/tag checkpoint-311 and deploy. Note: flash 'warning' was never whitelisted before 9bc68eb (recheck + retry-blocked warnings were invisible).

MERGED 2026-10-20: main = 9bc68eb = checkpoint-311 (Phase 1 history import), pushed from the laptop. Server: ACCOUNTING_V2_HISTORY_IMPORT=true already in prod .env (Amin added it early); server pull + migrate + build of 9bc68eb PENDING.

2026-10-20: checkpoint-311 LIVE (Amin's BBMS test: Blue Butterfly Montessori School file, 11,757 lines -> 4,178 txns, 0 warnings, staged). checkpoint-312 (2c18242) tagged: parser 1.1 matches types without spaces ('Pay Cheque' read as 'other' under 1.0), same bytes re-read when the parser version is newer and commit reclassifies in place, preview sample before commit. Server deploy of 312 pending; after it, re-upload the BBMS file once to reclassify the 204 Pay Cheque rows.

PHASE 1 VERIFIED ON PROD 2026-10-20: checkpoint-312 live; BBMS import 1 committed 4,178 new with 829 links; import 2 (same file, parser 1.1) 4,178 unchanged, 204 reclassified, 0 dup; 864 active payments, 829 linked (96%), so multi-invoice linking NOT needed now. Next candidates: phase 2 (QBO read-only backfill) or phase 3 (show similar history on a row).

PHASE 3 BUILT 2026-10-20 (Amin: 'از همون پیشنهاد خودت شروع کن'): branch work/phase3-history-context-20261020 = validation/phase3-history-context-20261020 (60451bd + test fix). "From past books" panel in the Record Keeping drawer, read only, behind ACCOUNTING_V2_HISTORY_CONTEXT (default off); HistoricalContextService (same client+company, active originating, accounts opposite the funding side, exact name first so near spellings stay apart, payable-only entries counted as uncoded); parser 1.2 adds history_lines.account_path (migration 2026_10_20_000003), same file re-upload fills it in place. CI green (SQLite 2709, PG 2386). Laptop-only failures: 8 ServiceTokenMinterTest (M2M key, environment, pre-existing). NOT merged: waiting for Amin's go for checkpoint-313; after deploy re-upload BBMS once to fill paths.

MERGED 2026-10-20: main = e2cc653 = checkpoint-313 (Phase 3), pushed from the laptop. Server pull + migrate + .env ACCOUNTING_V2_HISTORY_CONTEXT=true + config:cache + BBMS re-upload PENDING.

2026-10-20 PHASE 3 ON PROD (cp-313): panel verified with 7 test PDFs (Downloads/VA-BBMS-History-Test; counts exact, unknown vendor shows no panel). BBMS import 3 (parser 1.2) reclassified 4178 but 3,832/11,757 lines still had no path: QBD prints a parent's own lines under '<parent> - Other'. Parser 1.3 fixes it (BBMS 0/11,757, Axle 0/573 without path): branch work/history-path-other-20261020 = validation/... (CI green SQLite 2710, PG 2387), NOT merged, awaiting Amin's go for checkpoint-314 (no migration; re-upload BBMS once after). Seen on prod, not built: Enbridge GIFI ranked 9224 Fuel costs although history is 24/24 Utilities (next phase: history as a candidate signal); chosen_account_name shows '�' instead of '·' (chart names stored with wrong encoding, pre-existing).
MERGED 2026-10-20: main = d43a2e3 = checkpoint-314 (parser 1.3), pushed from the laptop; server pull + BBMS re-upload PENDING.
VERIFIED ON PROD 2026-10-20: checkpoint-314 live; BBMS import 4 (parser 1.3) 4178 unchanged, 2857 reclassified, lines without path 0 of 11757. Phase 3 CLOSED. Next candidates: history as a candidate signal for account+GIFI (Enbridge case), the '�' chart-name encoding bug, 'split across' label for multi-account entries.
