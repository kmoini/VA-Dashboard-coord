---
name: same-as-last-time-repeat-entry
description: "Bank Reconciliation \"Same as last time\" (cp-534, 2026-11-18): a statement line with no document is offered the accounts of the last earlier QuickBooks entry of the same amount; limits and the loan rule inside."
metadata:
  node_type: memory
  type: project
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-18T23:00:04.709Z
---

Bank Reconciliation, checkpoint-534 (commit 439adc8b), LIVE on prod 2026-11-18 (tagged, migrated, built); prod test on the Axle Corp. standing order still pending at the time of writing.

Owner's framing: Axle Corp.'s mortgage standing order (10,913.30 monthly = Mortgage BMO Bank Loan 3,600.06 + Interest BMO Mortgage 7,313.24, a Journal Entry in QuickBooks) is only the EXAMPLE; many bank lines have no document. So the feature is general, not loan-specific.

How it works:
- The mirror job reads the months BEFORE the statement period too (`accounting_v2.reconciliation_repeat_lookback_months`, default 3, one GL read per month). Only the period is mirrored.
- `App\Services\Books\RepeatedEntryFinder` keeps, on each line still waiting, the newest earlier QBO entry of the same amount (to the cent) on the same bank account: `bank_statement_lines.repeat_suggestion` (json).
- Page: hint under "No entry yet" + button "Same as last time"; `POST /recordkeeping/bank-lines/{line}/create-entry` with `repeat: true` creates a PENDING row with transaction_lines that each carry `external_account_id`. Nothing is booked or pushed by itself.
- Not offered on purpose: other side on a bank/card account (transfer), A/R or A/P, any sales tax line, sums that do not add up, an account no longer in the chart.

**Why:** Create the entry made one line on GIFI 9270 for a split payment, which is wrong; the accountant books these the way they were booked the month before.

**How to apply:**
- The engine classifies a row whose category says loan/mortgage as LOAN_PAYMENT, and decision 7 (accounting team) holds a loan payment with no principal/interest split even after approval. The repeat passes `principal_amount` (lines on liability accounts) and `interest_amount` to the draft, and `QuickBooksEntityMapper::linesToPost()` posts lines that all name their own account as they are. Do not remove either half.
- There is an existing Loans registry with schedules (Clients > Registry > Loans, `LoanSchedule`); a recorded schedule also splits instalments. "Same as last time" is the no-schedule path.
- A metadata key named `source` in a transaction writer file trips `TransactionSourceVocabularyTest` (regex on `'source' => '...'`); use another key name (`origin`).
- Open limits: exact cents only; first occurrence has nothing to copy; taxed recurring payments (rent with HST) not offered yet.

Related: [[bank-reconciliation-workspace]], [[automate-dont-add-manual-steps]], [[never-overrule-the-accountant]].
