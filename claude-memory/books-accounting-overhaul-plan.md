---
name: books-accounting-overhaul-plan
description: "SHIPPED to production 2026-08-08 — the whole accounting overhaul (phases 0-5 + inter-company). Books is HIDDEN from clients pending Amin's sign-off. Full record: va-dashboard2/docs/books-accounting-overhaul-record.md. Read before touching Books, transaction posting, chart of accounts, bank statements, reconciliation or inter-company."
metadata: 
  node_type: memory
  type: project
  originSessionId: f6eeabb2-cfa9-43ba-812e-85520b1ecf22
  modified: 2026-08-09T02:39:35.332Z
---

**SHIPPED 2026-08-08.** Everything below was built and is on production. The record of
what was actually built, why decisions changed, and what is still open:
`va-dashboard2/docs/books-accounting-overhaul-record.md`. Test script (Persian):
`docs/books-overhaul-test-guide-fa.md`. checkpoint-211 covers phases 0-5; commits
4d10b04, e6f49dd, a71c84f, 8c6603c landed after it.

⚠️ **Books is hidden from clients** — both sidebar entries are `platformOnly` until
Amin signs off. Restore `minLevel: 3` in `Sidebar.jsx` afterwards.
⚠️ **Credit / aging / tax Bigcapital endpoints have NEVER run against a live server.**
Request shapes came from docs. Same class of unknown that bit sub-accounts in phase 0.

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

**Phase 0 is BUILT and manually tested green (2026-08-05)** against a real
Bigcapital org — commits 6cb7680, 5d5f047, 6df80b6, ef23902. Doc:
`docs/books-phase0-chart-of-accounts.md`. NOT deployed. Facts it settled:
- Bigcapital **returns sub-accounts NESTED inside their parent**, not as sibling
  rows. Reading only the top level made them invisible, so re-importing hit
  `ACCOUNT.NAME.NOT.UNIQUE` for accounts we had just created ourselves.
- `parent_account_id` + `subaccount` on `POST /api/accounts` works end to end.
- Bigcapital **seeds a CODED default chart** at provisioning (40007, 50001 …), and
  there is **no delete-account path anywhere** — so Phase 1 must PREVENT the
  default chart when the accountant brings their own coding, not clean it up.
- Still unverified: `accountLedger()`'s real response shape (needs a bank account
  with posted transactions), and whether Bigcapital supports line-level tax.

**Phases 2, 3 and 4 BUILT 2026-08-06, NOT tested, NOT deployed** — commits c06c598,
29d653c, 0fbab98, f88e80a, 25e4e38. Persian end-to-end test guide:
`docs/books-overhaul-test-guide-fa.md`. Prod owes `migrate --force` (4 migrations).
- `TransactionPoster` posts an approved transaction to the ledger. Refuses rather
  than guesses (account matched by number then EXACT name); idempotent via a
  key derived from the transaction + unique index; un-approve writes a REVERSING
  entry; a locked or tax-submitted period refuses the write (the period lock had
  never gated anything before).
- A bill books against A/P and its settlement clears A/P, so an invoice and its
  receipt stop double-counting the cost. Control account found by TYPE, never name.
- GST/HST splits onto its own line: input tax credit on purchases, liability on
  sales. Tax account matched on a LIABILITY whose name names a tax.
- `bank_statement_imports` / `bank_statement_lines` + `BankStatementImporter`
  (finally calls the dead `BankCsvImporter`) + `BankLineMatcher`. Fingerprint
  dedup so re-uploading a month is safe. Amount is a PRECONDITION not a signal;
  two equally-good candidates are left for the human. Register UI in Books→Banking.
- ⚠️ Correction to an earlier claim: `voidInvoice`/`voidBill` DO preserve the audit
  trail — both capture the full document via `getInvoice`/`getBill` and log it with
  the reason before deleting, and refuse when payments exist.

**Phase 5 + OFX BUILT 2026-08-06** — commits cb58720, 98724ad, 7a4cc93, c6e37f4:
vendor credits, credit notes, Set Credits on Pay Bill, A/R + A/P aging, the
cash/accrual switch (basis now travels on `DateRange`), account search by number,
and OFX/QFX statements (format detected from CONTENTS, not extension — OFX 1.x is
SGML so a regex parser, not XML). Ships with the activity_logs CHECK widening for
`BooksVendorCredit`/`BooksCreditNote`. 313 tests pass.
⚠️ The credit and aging Bigcapital endpoints are NOT verified against a live server
— same class of unknown that bit sub-accounts in Phase 0.

**STILL NOT built:** PDF statements (needs an AiPromptCatalog entry), Tax Centre
page, reconciliation auto-tick from matched lines, undeposited funds / bank
deposit, deactivating unused default accounts.

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
