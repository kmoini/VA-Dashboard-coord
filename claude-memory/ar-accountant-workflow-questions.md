---
name: ar-accountant-workflow-questions
description: 2026-10-19 AR posting gap (deposit slip -> one line, accountant does Invoice -> Receive Payment -> Deposit); what the team's QB Home screen answered; question list sent to the accountants, answers PENDING.
metadata:
  type: project
---

Trigger: a BMO deposit slip (Illstyl3 cheque 6,107.65) became ONE V2 line flagged customer deposit / funding ambiguous / revenue vs liability. Amin: a real accountant does Create Invoice -> Receive Payments -> Record Deposits.

Current code (2026-10-19): AR_CREATION -> QBO Invoice; AR_COLLECTION with settles_transaction_id -> QBO Payment linked to the Invoice, DepositToAccountRef straight to bank (Receive Payment + Deposit merged). No Undeposited Funds support. No "cash in without invoice -> make the invoice" path (mirrors [[open-question-etransfer-without-bill]]).

Answered by the team's QuickBooks Home screen screenshot (2026-10-19):
- It is QuickBooks DESKTOP (Canadian), not Online. Our product only talks to QBO. Asked the team which one client books live in (question 0, the biggest open item).
- Sales flow: Estimates -> Create Invoices -> Receive Payments -> Record Deposits.
- They USE Undeposited Funds (badge "2" on Record Deposits): Payment goes to Undeposited Funds, then one Deposit groups the cheques of a slip.
- AP: Enter Bills -> Pay Bills (matches us).
- Sales Receipts icon hidden: assume they always invoice (confirm).
- Statement Charges in use (likely recurring charges such as rent).

Question list (accountant wording, Persian) handed to Amin; answers PENDING. Do not design the AR chain until they return. Respect [[never-overrule-the-accountant]].

ANSWERS from Amin (2026-10-19), questions 1 to 8 of the 32-question list:
1. Client books are QuickBooks ONLINE (the Desktop screenshot was only a reference for the workflow).
2. Management rule: the accountant must never be stuck. When a payment/cheque arrives with no invoice, WE issue the invoice from prior info, then apply the payment, and raise an alert "official invoice not received yet". When the official invoice arrives, UPDATE our invoice (not a second one).
3. Our invoice date = cheque date until the official invoice arrives, then updated.
4. Invoice number: same as date (provisional, replaced by the official one's number).
5. Not understood (item/Product-Service question); re-asked in plain words.
6. Sales tax by location: e.g. Ontario 13% HST, extracted from INSIDE the cheque amount.
7. Unknown customer: create a new customer from the name on the slip.
8. Yes: if the client already has an invoice in QBO, find it and apply the payment.
Open follow-ups asked: what "prior info" means for the generated invoice; official invoice with a different amount; province from client address or customer address.
Questions 9 to 32 still PENDING.

FOLLOW-UP ANSWERS (2026-10-19):
- "Prior info" for the provisional invoice = look in BOTH our system and QBO (e.g. that customer's previous invoices). A separate agent is building a learning system; reuse it, do not build a parallel one.
- Official invoice amount differs from the cheque: never auto-decide. The system explains the difference to the accountant and asks; the accountant answers in the same conversation and the system does exactly that. A separate agent is building per-transaction chat (accountant and client); hook into it, do not build a parallel one.
- Tax province = address of the CLIENT the accountant works for (not the customer's).
- Answer 7 confirmed: new customer from the name on the deposit slip.
Item question (5) re-asked, still open. Questions 9 to 32 still PENDING.

TEAM POLICY DOC RECEIVED 2026-10-22: Downloads/__پاسخ_سیاست_های_حسابداری_QuickBooks.docx (answers all 34 original questions + a 5-rule policy + 3 tiers: Auto-post / Suggest for approval / Hold-Missing information).
Key team rules: identify the nature first (sale vs prepayment vs deposit vs trust); invoice date = real sale/service date, NOT cheque date; invoice number = next QBO sequence, cheque number in Memo/reference; never assume HST; new customer = suggestion, approval when identity unsure; equal-amount open invoices = stop; Deposit date = real bank date (keep both dates); slip + cheque + bank line = ONE event; uncertain revenue vs liability = Pending Review, temporary posting only to a pre-approved suspense account; auto-post allowed only for: bank line to existing tx, payment to one certain invoice, grouped Deposit of identified receipts, approved fixed recurring rent, documented bank fees, reference data.
CONFLICTS with Amin's own answers (dates, number, always-13%, auto-create customer, "never stuck"). Proposed reconciliation: system PREPARES the provisional invoice as "Suggest for approval" so the accountant is never stuck but nothing posts on a guess. Amin must decide.
⚠️ Conflicts with live behaviour: [[historical-context-audit-2026-10-19]] found accounting.push sends UNAPPROVED rows; the team policy forbids that.

AMIN DECISIONS 2026-10-22 (after the team doc):
- NEVER ask the firm for exact account names per client: each accountant names accounts their own way. The system must FIND the account in that client's QBO chart (by account type/detail type + name, e.g. Undeposited Funds is a built-in QBO account), and when it is missing or ambiguous ASK the accountant once in the transaction, then REMEMBER that pick per client company (not across companies, see the DecisionMemory leak in [[historical-context-audit-2026-10-19]]).
- "Pre-approved suspense account" = approved by the accountant (or client) per client, same ask-once-and-remember flow.
- Rollout: EVERYTHING starts as "Suggest for approval". No auto-post until tested for a while.
