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
