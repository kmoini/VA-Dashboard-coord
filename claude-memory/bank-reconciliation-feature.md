---
name: bank-reconciliation-feature
description: "New Banking tab + bank reconciliation workflow in Books (VA-Dashboard), built 2026-07-06, NOT yet committed/deployed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3bc5d2f2-6674-473e-ba79-434504e1ac92
---

Built the classic bank-reconciliation workflow (pick a Bigcapital bank/cash account →
enter statement date + ending balance → check off cleared ledger entries until the
running difference hits zero → finish to lock) as a new "Banking" tab in
`d:\projects\VA-Dashboard`'s Books module. This was `va-dashboard-master-plan.md`'s
explicitly flagged top priority after Books Phase 3 shipped — see
[[bigcapital-ui-adaptive-design-goal]] and [[books-phase3-production-deploy]].

**Why:** the old `/bank-reconciliation` route was a literal "Coming Soon" placeholder,
hidden from nav, with no middleware at all. Books had 5 tabs but no Banking tab —
the single biggest gap against the QuickBooks-familiar workflow goal.

**Architecture:** the account + its ledger entries live entirely in Bigcapital
(reached via a new `AccountingProvider::accountLedger()` method built on the
already-verified-live `generalLedger` endpoint — no new Bigcapital endpoint needed).
Only the reconciliation session itself is local: two new tables
(`bank_reconciliations`, `bank_reconciliation_cleared_items`) + `BankReconciliation`/
`BankReconciliationClearedItem` models + a new `BankReconciliationController` (JSON
micro-API, not Inertia pages — same pattern as `BooksController::showInvoice/showBill`).
Gated `role.min.client:3`, same as the rest of Books (client-portal users can reconcile
their own accounts too — confirmed with user, not staff-only).

**How to apply:** before touching Books/Banking or `AccountingProvider`, know that:
- `accountLedger()`'s exact per-transaction Bigcapital field names (debit/credit/date
  keys) are **NOT verified against a live server** — the codebase's own test fixture
  (`BooksControllerTest`) leaves `transactions: []` empty. Confirm against a real
  Bigcapital response before trusting the register data in production.
- The old `/bank-reconciliation` route now redirects to `/books?tab=banking` instead
  of 404ing or serving the removed placeholder page.
- `chk_activity_logs_entity_type` (the DB CHECK constraint that broke a prod deploy
  before — see [[colleague-branch-integration-2026-06]]) was widened for
  `BooksBankReconciliation` in migration `2026_07_06_000007`.
- Full test suite: `tests/Feature/Bigcapital/BankReconciliationTest.php` (8 tests, all
  passing), plus confirmed no regression in `BooksControllerTest`/`QuickBooksProviderTest`
  (131 tests passing). `npm run build` succeeds.

**Status: NOT committed, NOT deployed.** Per [[wait-for-user-test-before-deploy]], stopped
here for the user to test locally before checkpoint/deploy. When it does ship, prod will
owe `php artisan migrate --force` (3 new migrations, including the activity_log constraint
widen) same as every other Books deploy.
