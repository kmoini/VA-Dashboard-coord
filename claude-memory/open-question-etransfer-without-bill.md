---
name: open-question-etransfer-without-bill
description: "RESOLVED 2026-10-02 by the accounting team: a payment (e-Transfer to a contractor/teacher) with NO bill or invoice in the books is held as a payment AWAITING ITS INVOICE, never expensed by the engine; expense without invoice only when a human is certain none exists. Implemented: BusinessEventResolver keeps AP_PAYMENT, adds AWAITING_INVOICE reason or settles_transaction_id when an open bill matches. READ before touching payment event rules, phase 4 settlement, or QBO push of AP_PAYMENT rows."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-02T19:34:42.298Z
---

**The case (local test 2026-10-02):** Interac e-Transfer, Blue Butterfly Montessori School → "Hannah music teacher", $520. Model proposed `AP_PAYMENT`; V2 kept it with `EVENT_UNSUPPORTED_FOR_POSTING` + `MISSING_SOURCE_ACCOUNT`, `needs_review`.

**Question Amin sent (2026-10-02):** payment to a contractor/teacher, no invoice/bill/payable recorded for that person and amount: (A) expense now + flag tax, (B) hold as payment/prepayment awaiting the invoice, no expense until the bill is in, (C) depends; and does a missing invoice alone block expense recognition for a contractor?

**Accounting team's answer (2026-10-02):** **B.** "پرداخت ابتدا به‌عنوان پرداخت/پیش‌پرداخت یا مبلغ در انتظار Invoice ثبت شود و تا زمانی که Invoice/Bill دریافت و ثبت نشده، به Expense نرود." A only when we are CERTAIN there is no invoice: "در کل همه پرداختی‌ها می‌بایست اینوویس داشته باشند مگر در مواقعی که اطمینان داریم بر اساس نوع کار و طرف حساب اینوویسی در کار نیست؛ به ناچار باید هزینه را بدون اینوویس شناسایی کنیم."

**Implemented the same day (local, after checkpoint-267):** `BusinessEventResolver::resolve` keeps `AP_PAYMENT`; `openBillFor()` looks for an unsettled expense-side bill/invoice of the same party and exact cents → modifier `settles_transaction_id` + `bill_found` (phase 4 links it); otherwise modifier `awaiting_invoice` + new `ReviewReason::AwaitingInvoice` (`AWAITING_INVOICE`, dimension event) → `needs_review`. Tax stays `OUT_OF_SCOPE` by rule (tax belongs on the invoice). The engine NEVER downgrades to EXPENSE_PURCHASE; "certain no invoice" is the accountant's call (they change the event / approve). Logged in `docs/ACCOUNTING-V2-DECISIONS.md` (entry 3), tests `AwaitingInvoiceTest`.

**Still open for phase 4:** what a held payment posts as while waiting (supplier prepayment asset is the natural home) and the link when the bill arrives later. Related: [[accounting-v2-phase2-status]], [[document-role-triage]], [[never-overrule-the-accountant]].

**Update 2026-10-05 (team answers to the 7 questions, DECISIONS.md sections 4-10):** decision 4 adds "book fast + red flag missing document, accountant clears, optional N-day auto-clear"; the posting target while waiting (A nothing / B prepayment asset / C payment on account in A/P) is still the owner's call; recommend C.
