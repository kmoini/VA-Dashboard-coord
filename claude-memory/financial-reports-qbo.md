---
name: financial-reports-qbo
description: "/reports financial statements read from QuickBooks: 8 reports, AI Assistant, client workspace, who pays, usage page, ALL LIVE and verified through cp-530 (2026-11-18); only charging left and it is PARKED. READ before any /reports, period close, report-by-AI or report billing work."
metadata:
  node_type: memory
  type: project
  originSessionId: e8b3c4c2-bd7f-4070-908f-a479db8e2721
  modified: 2026-11-18T19:02:58.284Z
---

Full record, and the place to start: `va-dashboard2/docs/financial-reports.md`, section "Where it stands (read this first)" (table of what is live per checkpoint, decisions, open items, lessons, test data), then one section per checkpoint.

**State 2026-11-18:** everything agreed is LIVE on production and verified there by Amin, through checkpoint-530 (server HEAD 67efe4f2). The doc update of 2026-11-18 was handed to Amin as checkpoint-531 (docs only). Next free checkpoint after it: 532, but check origin tags first.

Live: Profit and Loss, Balance Sheet, Cash Flow, AR/AP Aging, Trial Balance, General Ledger, Sales Tax Summary (GST/HST); columns by month/quarter/year; compare to previous period/year; drill-down to one account's ledger; aging settings; per-client period close and month chooser on /period-lock; the AI Assistant brings a report (accountant and client workspace); reports in the client workspace; who-pays setting; /reports/usage.

**Decisions by Amin that hold:**
- A report is read only on request; every request is counted in `report_requests`.
- WE CHARGE THE CLIENT (the business whose books they are), never the accountant or firm; a firm MAY choose to cover a client (`clients.reports_covered_by_firm_id`). I misread this twice (asking workspace; connection owner): do not repeat.
- ⏸ Charging is PARKED: the overall billing model is undecided (a credit system is being considered). Do not build price, allowance, card capture or invoices, and do not ask about them again, until Amin says the model is decided. See [[stripe-payments-architecture]].
- No second AI: reports go through the existing assistant ([[global-ai-assistant-agent]]).
- Nothing outside `app/Reports/Sources/` names QuickBooks.
- "Reviewed" = the accountant closed the period ([[never-overrule-the-accountant]]).

**Open, not blocking:** charging; a client CREATED BY A FIRM cannot be given a workspace login (an invitation creates a new client; flagged only); unverified with real data: two tax agencies, TaxSummary basis, a long General Ledger (no paging).

**Lessons:**
- QBO API has no comparison and omits Gross Profit (we derive both); ledger ColType is the column KEY; `reports/TaxSummary` needs `agency_id`; `num_periods` counts the "and over" column.
- Gemini flash-lite's structured fields are unreliable: read period and client from the user's words in code.
- New assistant instructions = a NEW prompt key appended in code, so no publish step is needed ([[ai-prompt-registry]]).
- `Log::info` does not reach the production log.
- ⚠️ A colleague (OstvarH, SameBooks) pushes to `main` without tags and another session shares checkpoint numbers: before every hand-off `git fetch origin`, read `git log HEAD..origin/main` and `git tag`, pull first (Amin allowed it), and tell Amin to check `git push origin main` did not say `rejected` before deploying.

**Test data on production:** sandbox "Sandbox Company CA f148" is connected to TWO clients since 2026-11-18: "Kamyar" (firm of Mahdi Yousefi) and the self-serve workspace "kamyar moini" (only to test the client side; can be disconnected from Integration there). Reference figures: P&L 2026-07-01..09-30 accrual, Total Income 26,392.50, PROFIT 15,162.68. Some sandbox account names hold a broken character (`15600 � Operations Expense`); it is in QuickBooks' own chart of accounts, not our bug, left as is.

Related: [[qbo-api-read-quota]], [[tests-step-by-step]], [[checkpoint-rule]].
