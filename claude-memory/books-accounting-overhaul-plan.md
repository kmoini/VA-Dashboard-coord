---
name: books-accounting-overhaul-plan
description: "LOCKED 2026-08-04 six-phase plan to make Books/Record-Keeping/Document-Hub a real double-entry system (accountant's 9 requirements). PLAN ONLY, nothing built. Read before touching Books, transactions posting, chart of accounts, bank statements or reconciliation."
metadata: 
  node_type: memory
  type: project
  originSessionId: f6eeabb2-cfa9-43ba-812e-85520b1ecf22
  modified: 2026-08-04T23:56:40.765Z
---

Full audit + build order: `va-dashboard2/docs/books-accounting-overhaul-plan.md`
(checkpoint-205, commit b300a91). Driven by Amin's company accountant reviewing
the product against QuickBooks Desktop and raising 9 requirements.

**Locked with Amin 2026-08-04:**
1. Source of truth = **option A**: Record Keeping is the queue, Books/Bigcapital
   is the ledger, approve posts to it; a local `transaction_lines` table keeps
   the double-entry form so a future move off Bigcapital is possible. May change
   later.
2. **GST/HST is in scope and lands in Phase 2**, not Phase 5 — `transaction_lines`
   needs `tax_code`/`tax_amount` from its first migration.
3. Build order Phase 0 → 1 → 2 → 3 → 4 → 5.
4. **No deploy until every phase is done and tested.** Per-phase manual test with
   Amin, full end-to-end at the end. Checkpoints/tags still happen; deploys do
   not. Overrides the usual per-checkpoint deploy habit — see
   [[wait-for-user-test-before-deploy]].
5. Amin owes: the accountant's own coded chart, and real sample files (a
   QuickBooks Desktop CoA export + real bank statements as CSV and PDF from more
   than one bank). Phase 3 is blocked on the files.

**Findings that cost real effort to derive — do not re-derive:**
- `transactions` has NO link to the chart of accounts, no debit/credit line
  structure, and no settlement link. An uploaded invoice and its payment receipt
  each become an independent `expense`, so cost is **double counted**.
- **Approved transactions never reach the ledger.** `AccountingProvider` is used
  only by Books, the migration engine and CSV importers. So Balance Sheet and
  P&L today show only what was typed directly into Books, none of the AI or
  accountant work in Record Keeping.
- `CanadaProfile::defaultCoATemplate()` (16 coded accounts incl.
  `2200 · GST/HST Payable`) and `taxRates()` (GST/HST/PST/QST) already exist but
  have **no production caller** — `ProvisionBookJob` uses only code/currency/
  fiscalYearStart. master-plan.md wrongly claims the seeding shipped.
- `SmartImportService` implements the whole "Add" half of a bank feed
  (vendor → rule → AI against the real CoA, then a balanced 2-line journal) but
  has **no caller**; it posts journals straight at bank accounts (the QuickBooks
  anti-pattern), is not idempotent, matches accounts by name substring, and
  never does "Match". `BankCsvImporter` is likewise complete with zero callers.
- `CsvAccountImporter` drops sub-accounts (`AccountDTO` has no `parent_id`) and
  dedups on NAME, so a real QuickBooks Desktop export loses both its hierarchy
  and its codes.
- ⚠️ `BigcapitalProvider::accountLedger()` falls back to `uniqid()` for a ledger
  row id when Bigcapital omits one — every reload then mints new ids, orphaning
  cleared items and drifting the reconciliation difference. Its field names were
  never verified against a live server.
- Open risk: no evidence Bigcapital's API supports **line-level tax** anywhere in
  the codebase. Verify in Phase 0; fallback is a separate line at GST/HST Payable.

Related: [[bank-reconciliation-feature]], [[record-keeping-ai-voice-edit]],
[[document-hub-folders]], [[books-phase3-production-deploy]],
[[bigcapital-tenant-storage-ceiling]], [[books-multi-company-plan]].
