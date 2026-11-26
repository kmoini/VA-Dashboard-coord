---
name: entry-date-document-then-bank
description: "Accountant's rule relayed by Amin 2026-11-25: a document paid in a later month is dated by the bank statement (the day really paid); bank date also when no date is read; nothing stalls, what is missing is notified and reported."
metadata:
  type: feedback
---

The accountant, relayed by Amin on 2026-11-25 after the 360.00 difference (Aurora Star Tech bill, Axle Corp. September 2026, Desktop vs QuickBooks Online). Amin corrected my first reading the same day; this is the corrected one:

- In principle an expense or income is recorded on the date it is recognised (the document's date).
- In the real world an invoice is often NOT paid in the month it arrived. Then the basis is the bank statement: the entry is dated the day the money really moved. This is why her Desktop bill for Aurora is dated 09/09 (the payment), and she says it will happen very often with other companies (her estimate: 70 to 80 percent are untidy).
- Also when the document's date is not read, or there is no document: the bank statement date.
- The system must work automatically and never leave work stuck. What is missing is told to the accountant or the business owner: "I booked this entry but its document is not of this month", and the missing documents.

My first reading was wrong: I took it as "the document date always wins, do not copy Desktop". Do not repeat that.

**Why:** the pilot's goal is books that close without waiting on paperwork, with the gaps visible instead of blocking.

**How to apply:** a bill or invoice PAID in a later month than its document is dated by the bank line that paid it; same month or unpaid keeps the document date; no readable date uses the bank date; mark where the date came from; prefer book-and-flag over hold. Amin answered 2026-11-25: income follows the same rule; any later month counts (28 Aug paid 3 Sep goes to September); an entry already in QuickBooks in a month that is finalized or tax-filed is NOT moved, only reported. Built as cp-580 (`App\Accounting\V2\DocumentDate`, doc docs/DOCUMENT-DATE-PAID-IN-A-LATER-MONTH-2026-11-25.md). Still to build, agreed order: the per-period report of missing / other-month documents, then notifications, then a review of places that hold a push. My reading (not hers): a notification and a per-period report of missing or other-month documents is new work, not built as of 2026-11-25; Amin had not yet given the go-ahead.

Related: [[enter-like-the-accountant]], [[statement-decides-cash-side]], [[never-overrule-the-accountant]], [[automate-dont-add-manual-steps]].

cp-580 LIVE 7e87496f; first prod run on Aurora (Bill 22345, row 2562, 2026-08-17 to 2026-09-09) ended 'conflict': our own statement BillPayment had moved the Bill's SyncToken. cp-581 (awaiting push): update() takes the live token for a Bill/Invoice when TotalAmt is ours and every LinkedTxn payment is ours; documents() re-asks a conflict row.

cp-581 LIVE 3f07363d: Aurora Bill 22345 re-dated to 2026-09-09 (our side confirms; QBO screenshot still owed by Amin). cp-582 (3949dcee, awaiting push): `StatementFollowUp` = list of entries recorded with no document + documents of another month; 'To follow up' tab on Bank Reconciliation and two sections in the Finalize report (snapshot.follow_up). NEXT agreed: notifications to accountant/owner from the same list, then a review of places that hold a push.

cp-582 LIVE 3949dcee; report #4 Detail shows 'Documents of another month' (Aurora, Comfort) correctly. cp-583 (awaiting push): StatementFollowUpNotifier at Finalize (Amin 2026-11-25: BOTH in-app and email, AUTOMATIC at Finalize): bell for assigned accountant + finalizer + client users, StatementFollowUpMail to client.email; once per list fingerprint (snapshot.follow_up_told). ⚠️ sends a REAL email to the client's address on the next Finalize with a non-empty list. Desktop A/R + A/P aging PDFs received (totals 17,787.58 / 44,938.57 = balance sheet); Online aging not yet sent.

cp-583 LIVE f0c193bc and VERIFIED on prod 2026-11-25: bell notification + email to kmoini@homeleaderrealty.com both arrived, content right. Email landed in SPAM (Outlook/Exchange). Public DNS of voiceaccountant.com: SPF '+a +mx +ip4:45.79.116.146 ~all' (no include for a mail service), DMARC p=none, DKIM selectors default + s1/s2 (SendGrid CNAMEs). cp-584 (awaiting push): plain-text part + Outlook-safe button. Real cause of spam not known until Amin sends the message headers (Authentication-Results) and which mailer prod uses.

cp-584 LIVE 0ba09137. Prod mailer = Resend (noreply@voiceaccountant.com); Resend DNS (resend._domainkey, send. SPF/MX) is all present, DMARC p=none; spam cause unknown until headers arrive. Step 4 review done 2026-11-25; Amin chose D + A (NOT B uncategorized account, NOT C fx rate). cp-585 (awaiting push): follow_up.not_in_quickbooks list (staff bell only, owner not emailed; owner_fingerprint) + bank-line push takes any unsent bill/invoice the payment pays (StatementSettledSync::unsentDocumentsPaidBy, line shows 'Goes with it').
