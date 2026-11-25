---
name: returned-cheque-reverse-the-deposit
description: "cp-578 (2026-11-25): Reverse the deposit on a Returned Item bank line: journal entry debit A/R of the customer, credit bank, on the bank date; the accountant's own way for a bounced cheque."
metadata:
  type: project
---

Checkpoint-578 (va-dashboard2, commit d43e84c1), built 2026-11-25, awaiting Amin's tag/push; NOT yet tried on production or real QuickBooks.

The accountant (via Amin, 2026-11-19) on the Axle returned cheque 7,229.50: she booked neither line in Desktop, but the right way is money in recorded, then the return recorded too, as a journal entry. So two ways stay on the page: **Exclude both** (no entries) and **Reverse the deposit** (deposit matched to the customer's payment, then one press on the Returned Item line).

- `App\Services\Books\ReturnedCheque::reverse`: pending entry, event CUSTOMER_ADVANCE_REFUND with modifier `returned_cheque`, settled on the return line; payment gets `returned_by_bank`.
- A returned payment pays no later invoice (`SettlementLinker`), gets no invoice offer, has no open deposit left.
- Doc: docs/RETURNED-CHEQUE-REVERSE-THE-DEPOSIT-2026-11-25.md.

**Limit:** when the cheque had paid an invoice, QuickBooks keeps the invoice paid and the journal as an open charge; re-applying the payment to the journal is still done in QuickBooks.

Related: [[statement-decides-cash-side]], [[bank-reconciliation-workspace]], [[think-like-a-quickbooks-accountant]].
