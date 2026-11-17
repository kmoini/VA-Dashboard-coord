---
name: financial-reports-qbo
description: "/reports financial statements read from QuickBooks (P&L, Balance Sheet, Cash Flow, AR/AP aging); stages 1-4 LIVE cp-489 2026-11-14, awaiting Amin's prod test; stages 5-6 + pricing pending. READ before any /reports, period close or report-by-AI work."
metadata:
  node_type: memory
  type: project
  originSessionId: e8b3c4c2-bd7f-4070-908f-a479db8e2721
  modified: 2026-11-14T19:41:25.079Z
---

Full record: `va-dashboard2/docs/financial-reports.md` (architecture, decisions, manual test guide, server steps).

State 2026-11-14: stages 1 to 4 LIVE on production as checkpoint-489 (d9ac9069; both migrations ran, server `git log -1` confirmed). Awaiting Amin's production test: the page had not been seen in a browser or run against real QuickBooks before deploy.

First prod test by Amin 2026-11-14: all five reports read from the real sandbox QuickBooks fine. Fixes LIVE as checkpoint-490 (df89b844) and checkpoint-491 (ed106c6d, server git log -1 confirmed 2026-11-14; next free 492). cp-491: the QBO API omits Gross Profit, so QboReportNormalizer derives it (Income total less COGS total) when absent; "More periods" list (calendar only, fiscal needs the fiscal year start we do not hold); P&L figures matched the QuickBooks PDF line by line: /period-lock had NO link anywhere (now linked from /reports "Period close"), back link on top of the old activity reports, ledger follows the header client, empty report state, review wording. Still owed by Amin: figures compared against QuickBooks itself, /period-lock firm-wide close test.

Decisions by Amin (2026-11-14):
- A report is read only on request; every request is counted in `report_requests` with no charge.
- ⏸ Pricing model and who pays (firm or business owner) are DEFERRED to a management meeting Amin will hold. Do not build charging until he relays the outcome.
- Do NOT build a new AI. The existing AI Assistant (`AiAssistantService`, the chat widget) must fetch reports through `App\Reports\ReportService` (stage 6, not built).
- Other accounting systems will be added later: nothing outside `app/Reports/Sources/` may name QuickBooks.
- Both accountant and business owner get reports; the report states its review status. "Reviewed" = the accountant closed the period, never "pending count is zero". A personal workspace (`is_personal`) is never shown as reviewed.
- Per-client period close added beside the firm-wide one on /period-lock.
- The page must follow `docs/DESIGN-SYSTEM.md`.

Still to build: stage 5 (client workspace access; `ResolveTenant` firewall blocks `reports.*` for portal users, firm-wide Transactions Summary must stay closed to them), stage 6 (AI Assistant), previous-period comparison, old Client Ledger page still has its own client dropdown.

⚠️ Found: `transactions.locked_by` was never migrated, so the firm-wide period close on /period-lock always failed with "Failed to lock period". Fixed by migration `2026_11_14_000002`; live with cp-489.

Related: [[qbo-api-read-quota]], [[stripe-payments-architecture]], [[global-ai-assistant-agent]], [[never-overrule-the-accountant]].

## 2026-11-14 evening: cp-492 live, tomorrow's queue, QuickBooks gap report

- checkpoint-492 LIVE (72bd99e9, server `git log -1` confirmed): fiscal, "Since N days ago" and upcoming periods in "More periods"; fiscal year start read from QuickBooks CompanyInfo via `ReportSource::fiscalYearStartMonth()` (cached 30 days). Next free checkpoint: 493.
- Amin asked, to be built 2026-11-15 (he said stop for today, opinion only):
  1. `/period-lock`: let the accountant choose the month freely (today it only offers the latest month with unlocked transactions).
  2. "The fiscal periods must also be updated in the client profile". My reading (not confirmed by Amin): the fiscal year fields that already exist (`clients.fiscal_year_end`, `client_company_profiles`, `CompanyProfileCard.jsx`) should be filled from what QuickBooks says. Confirm the reading before building.
- Gap report by a Claude coworker with browser access to the sandbox: doc "QuickBooks Online Reports vs VoiceAccountant: Gap Analysis", https://claude.ai/artifact/7XkxcYibhm2A1wZAiGGpr9 (read with the Claude Docs connector, doc id 34e23c54-2ad6-4c5b-9f59-7424e23321e6). Facts from it:
  - QuickBooks has 104 distinct standard reports; we have 5. Period list has 52 options on P&L, Balance Sheet, Cash Flow; 51 on the aging reports. Ours is on P&L and Cash Flow only.
  - "Recent" = today minus 4 days to today (Nov 10 to 14). "This fiscal week" = Sunday to Saturday (Nov 8 to 14). "All Dates" = no dates, and it gives different figures (probably future-dated entries; not proven).
  - Biggest gaps: Display columns by (Months/Quarters/Years/Class/Customer...), Compare to (PY, PP, YTD, $ and % change, % of income), drill-down to transactions, aging settings (method, days per period, number of periods), filters, show rows non-zero, negative number format, Excel export, email/schedule/save.
  - Its top ten to add: Trial Balance, General Ledger, Transaction Detail by Account, GST/HST Summary, GST/HST Detail, Reconciliation Reports, P&L by Month, Journal, Transactions without sales tax, Balance Sheet Comparison.
- My recommendation given to Amin (he has not decided): first columns by month/quarter/year + compare to previous period/year; then Trial Balance + General Ledger + drill-down; then aging settings and detail; GST/HST after checking the API offers it for Canada. Do not copy cosmetics (header/footer, section titles) or Insights (stage 6 covers it). Every extra report or comparison is extra Intuit reads, which touches the deferred pricing decision.

## 2026-11-16: checkpoint-514 built locally (513 was taken by the registry docs session) (handed to Amin, not yet confirmed live)

Amin: "start per your own recommendation". Built, 48 report tests green, `npm run build` OK:
- `/period-lock`: "Month to close" list of every month with unlocked transactions (`openPeriods` prop); suggests the latest month that has ended.
- Columns split (total, month, quarter, year) on Profit and Loss, Balance Sheet, Cash Flow: `ReportRequest::$columns`, `ReportType::hasColumnChoice()`, QuickBooks `summarize_column_by`, part of the cache key, landscape PDF above four columns. ⚠️ `summarize_column_by` values not yet verified against real QuickBooks; Amin tests on production.
- The "fiscal year in the client profile" item needed nothing: `CompanyProfilePrefill` already offers `fiscal_year_end` from QuickBooks' FiscalYearStartMonth.
- Next on the list after Amin's test: compare with previous period/year (second read + $ and % change), then Trial Balance, General Ledger, drill-down, aging settings. Next free checkpoint after this one: 515, but always check `git tag` first: another session shares the numbers.

## 2026-11-16 later: cp-514 LIVE, cp-515 built locally

- checkpoint-514 LIVE (07e42d25, server `git log -1` confirmed): month chooser on /period-lock + columns split. Amin has not yet reported his production test of either.
- checkpoint-515 built locally and handed to Amin (56 report tests green): "Compare to" Previous period / Previous year on Profit and Loss and Balance Sheet. `ReportRequest::$compare`, `compared()`, `datesLabel()`; pure `App\Reports\ReportComparison` merges two ordinary cached reports into four columns (now, earlier, Change, % change); counted once; only with one Total column.
- ⚠️ Checkpoint numbers are shared with another live session (513 was taken under me). Run `git fetch --tags origin` and read `git tag` right before handing over a number.
- Next after Amin's test: Trial Balance, General Ledger + drill-down, aging settings; GST/HST only after checking the API offers it for Canada.

## 2026-11-16 evening: cp-515 LIVE, cp-514 verified, cp-516 built locally

- checkpoint-515 LIVE (933727aa, server confirmed). Comparison not yet tested by Amin on production.
- checkpoint-514 VERIFIED by Amin's screenshots: /period-lock month list works; P&L split by Months works against REAL QuickBooks (`summarize_column_by=Month` accepted, Jul/Aug/Sep 2026 + Total, Gross Profit in every column, totals match).
- checkpoint-516 built locally, handed to Amin (57 tests green): Trial Balance as a sixth report type (`trial_balance` → `reports/TrialBalance`, period, has basis, no split, no comparison). Not yet verified against real QuickBooks.
- General Ledger NOT built: needs column types (text columns are shown as money today). Then drill-down, aging settings.

## 2026-11-16 night: cp-516 LIVE, cp-517 built locally

- checkpoint-516 LIVE (165b822d, server confirmed): Trial Balance. Amin has not yet sent screenshots of Trial Balance or of "Compare to" (cp-515); both still unverified against real QuickBooks.
- checkpoint-517 built locally, handed to Amin (60 tests green): General Ledger as a seventh report (`general_ledger` → `reports/GeneralLedger`); `FinancialReport::$columnTypes` ('money'/'text') + `$labelTitle`, `QboReportNormalizer::columnTypes()` from QuickBooks ColType; text columns on page, PDF, CSV. No paging yet (long periods = thousands of rows).
- Next: drill-down from a figure to its transactions, aging settings; GST/HST only after checking the API for Canada.
- checkpoint-517 LIVE (3a727871, server confirmed 2026-11-16). Waiting for Amin's three production screenshots: Compare to (515), Trial Balance (516), General Ledger (517). Do not start drill-down before them. Next free checkpoint 518 (check `git tag` on origin first).
- 2026-11-16: Amin's screenshots VERIFIED cp-515..517 against real QuickBooks (Compare to matches QuickBooks' screen; Trial Balance totals 172,476.51 both sides; General Ledger sends Date, Transaction Type, Num, Name, Memo/Description, Split, Amount, Balance). One fault fixed as checkpoint-518 (built locally, handed over): a bare heading from an empty earlier period no longer appears in a comparison. Next: drill-down, aging settings.
- checkpoint-518 LIVE (4e9449b8) and seen fixed by Amin. checkpoint-519 built locally, handed over (63 tests green): drill-down. Rows carry `ref` (QuickBooks account id); a figure on a P&L / Balance Sheet / Trial Balance line links to General Ledger with `account=<ref>` (`ReportRequest::$account`, `ReportType::hasDrillDown()`). ⚠️ `account` filter on reports/GeneralLedger not yet verified against real QuickBooks. Next: aging settings; GST/HST after checking the API for Canada.
- checkpoint-519 LIVE (fcb62bf7, server confirmed 2026-11-16). Waiting for Amin's production test of the drill-down (Rent Expense 3,750.00, Jul to Sep 2026). Next free 520.
- 2026-11-16: drill-down VERIFIED on production by Amin (account filter works). Fault found: on a ledger QuickBooks ColType is the column KEY (subt_nat_amount, rbal_nat_amount...), not 'Money', so amounts showed as text. Fixed as checkpoint-520 (built locally, handed over): money told by key or title. Next after that: aging settings; GST/HST after an API check for Canada.
- checkpoint-520 LIVE (331fdbb2) and VERIFIED by Amin (ledger amounts formatted). checkpoint-521 built locally, handed over (65 tests green): aging settings on AR/AP aging (count from report date or today, days per column, number of columns; QuickBooks aging_method=Current, aging_period, num_periods, sent only when changed). Not yet verified against real QuickBooks. After it: GST/HST needs an API check for Canada; then stage 5 (client workspace) and stage 6 (AI Assistant) are still open.
- checkpoint-521 LIVE (697ed095) and VERIFIED by Amin 2026-11-16: aging_period and num_periods accepted by real QuickBooks (15 days x 6 gave 1-15 ... 61-75 and '76 and over'; num_periods COUNTS the 'and over' column; total stayed 17,562.04). The 'Today' method was not actually exercised in his screenshot (select still read 'The report date'); asked him to rerun that one step. QBO gap list is now done except GST/HST. Proposed next = stage 6 (AI Assistant fetches reports); waiting for Amin's go. Stage 6 notes: new assistant action needs the assistant.system-accountant prompt changed, which on prod is a DB override ([[ai-prompt-registry]]), so it needs a publish step at /admin/ai-instructions; local Gemini calls hang on this Windows box ([[global-ai-assistant-agent]]). Next free checkpoint 522.
- 2026-11-16 evening: Amin ran AR aging as of 2026-10-31 with 'Today' selected: a fresh read, but figures IDENTICAL to 'The report date' (Harbour Light still 1-30 / 31-60). So aging_method=Current had no visible effect via the API; meaning or support unconfirmed (a web search found no official parameter reference). Asked Amin to compare on QuickBooks' own screen (Customize, Aging Method: Current vs Report date, as of 31/10/2026). If QuickBooks' screen DOES change, our parameter is wrong or ignored: fix or remove the 'Count lateness from' control. If it does not change either, keep it. Stage 5 vs 6 vs GST/HST choice still waiting on Amin.
