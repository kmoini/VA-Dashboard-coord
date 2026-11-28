---
name: money-in-invoice-payment-deposit
description: "Money from a customer is Invoice, then Payment, then Deposit, prepared by the system itself; never a sales receipt, never an offer that waits for a click"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-27T20:14:53.797Z
---

Amin, 2026-11-27, relaying the accountant "for the umpteenth time" (QuickBooks Desktop flow: Create Invoices, Receive Payments, Record Deposits): money received from a customer is entered as an invoice, its payment and the deposit. October of Axle Corp. went wrong on two tenants (a sales receipt for IllStyle3; a payment with no invoice on an empty namesake customer for Miura) and Amin said: "we cannot hit these problems for every single customer".

**Why:** both failures were evidence the system already had and only displayed: `history_cycle` said on account 20 of 20 and was "a suggestion only"; the invoice like the books was an offer nobody clicked (and for Miura nothing was offered at all).

**How to apply:** when the company's books are clear, act on them, do not show them as a hint or an offer. Fix the rule, never the one customer. Built as checkpoint-603 (commit 6f012634, va-dashboard2): `InvoiceLikeTheBooks::settle()` at row creation and at the bank match, `event_from_books`, estimate mode for an amount never invoiced (Amin left the choice to me: estimate shown as such, one Approve), `CorporateTaxAccount` (TXINS is never sales tax or A/P), and `quickbooks:rebook <row> --as=customer-payment|corporate-tax [--apply]` for entries already in QuickBooks in the wrong shape. Doc: `docs/MONEY-IN-INVOICE-BY-ITSELF-2026-11-27.md`. My reading: a Payment deposited straight to the bank on the bank date stands for the Deposit step unless several cheques share one deposit; not confirmed by the accountant.

Axle Corp. facts worth keeping: the QuickBooks connection is id 17 (not 16); this accountant posts GST-P straight to GST/HST Payable and leaves the Receiver General bills open; the income tax instalment account ("Corprate income tax instalment") existed only in Desktop on 2026-11-27. October repair (rows 2595, 2596, 2597; duplicate 2576) was NOT yet run when this was written. Related: [[enter-like-the-accountant]], [[automate-dont-add-manual-steps]], [[think-like-a-quickbooks-accountant]].
