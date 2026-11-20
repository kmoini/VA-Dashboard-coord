---
name: statement-decides-cash-side
description: "cp-537 (2026-11-19): bank statement line decides the cash side of a QuickBooks push: bank date, bill paid from its line, returned-item pairs, no expense on a bank account. Came from the Axle Corp. Desktop vs QBO comparison."
metadata:
  type: project
---

Checkpoint-537 (va-dashboard2, commit b5acb636), LIVE on prod 2026-11-19 (migrated, built); the correction on import 94 was applied and verified the same day: Payments 22331, 22336 and JournalEntry 22335 moved to the bank date, Bills 22333 and 22337 paid (BillPayments 22341, 22342). Left for the accountant: delete Payment 22330 and Expense 22332 (the returned cheque). Built after comparing Axle Corp. September 2026 in QuickBooks Desktop (the accountant's) with QuickBooks Online (our pushes). Every difference was ours; the opening-balance gap of 12,602.65 was exactly three entries pushed with their DOCUMENT date before September.

Rules now in the push path (event posting on):
- Cash side (Purchase, Deposit, Payment, BillPayment, Transfer, bank journals) goes on the BANK date of the one statement line the row is settled on (`LedgerEntryDTO::cashDate()`); Bill / Invoice / VendorCredit keep the document date. Date sent is kept in `business_event_modifiers.qbo_txn_date`.
- A Bill settled on a statement line is paid from it (accounting team said yes, 2026-11-19): `QuickBooksExportProvider::payBillFromStatement`, `PayBillFromStatementJob`, id kept in `qbo_statement_bill_payment_id`. One sync row per transaction, so this id lives in modifiers; the register mirror checks it to count the BillPayment as ours.
- `ReturnedItemPairer`: "Returned Item"/NSF line paired with the same-amount deposit within 10 days (`returned_with_line_id`); "Exclude both" only while neither has an entry.
- Mapper refuses an Expense/Bill on a BANK account it derived (GIFI 1002 on an expense resolved to "Chequing"); the accountant's own pick stands.
- `StatementSettledSync::forLine` (called by `BankLineConfirmer` on every match) re-syncs an already pushed entry to the bank date / pays the bill. `php artisan bank-reconciliation:correct-quickbooks {import} [--apply]` does it for statements matched earlier.

**Why:** the accountant reconciles on bank dates; a cheque dated August and banked in September must sit in September.

**How to apply:** do not put the bank date into `payloadHash()` (it would wake every pushed row stale). Still open for Axle: monthly rent invoices (income + HST collected) are keyed by the accountant and never reach VA; payments with no bill carry no expense or HST; the Hydro document was an overdue notice with no HST printed.

Related: [[bank-reconciliation-workspace]], [[same-as-last-time-repeat-entry]], [[never-overrule-the-accountant]], [[sales-tax-hst-gst]].
