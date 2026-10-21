---
name: historical-context-roadmap
description: "Phase map of the historical-context plan (audit section 13): which phases are done, which one is in progress, which remain. READ before any history/profile/pattern/resolver work and keep it updated."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-20T17:56:42.217Z
---

Source plan: Downloads/VoiceAccountant-Historical-Context-Architecture-Audit-2026-10-19.md, section 13. Details of each done phase: [[historical-context-audit-2026-10-19]].

DONE (all on production, verified by Amin):
- 0a push gate, 0b company-scoped memory (flag ON in prod), 0c QBO token reliability: cp-309, cp-310 (2026-10-19/20). 429 back-off and read counter from 0c NOT done (moved to phase 2).
- 1 history import, QBD Transaction Detail CSV/xlsx: cp-311, cp-312.
- 3 retrieval + "From past books" panel, read only: cp-313, parser 1.3 account paths cp-314 (2026-10-20). BBMS: 4,178 txns, 0 of 11,757 lines without a path.

IN PROGRESS (started 2026-10-20, Amin's call, pulled forward from phase 6). BUILT on branch work/phase4-history-decisions-20261020 = validation/... (4bcb824, 64474c3, 0a80517 + test fix), CI green (SQLite 2720, PG 2397), MERGED 2026-10-20 as cp-315 (main 127de8e), pushed from the laptop; server deploy PENDING; flag stays OFF, migrate, run `php artisan history:decisions 11` (BBMS company id 11, client 73) dry run, then decide switch on + --apply. Includes: history_account_links (per company), one-click link on a row, link by picking the account, Accounting History 'Accounts in the past books' section. BBMS registry: Chequing 3922 matches by digits; history cards 7852/7878 do not match registered 8073/8725 (must be linked once).
- History as a decision source: when the company's history is clear (proposal: at least 3 entries and 80% to one answer) the engine PICKS the account (GIFI follows), and the funding account (which bank/card), shows the other candidates with counts in What happened, writes the reason ("from past books: 24 of 24"). The recording cycle (bill then pay vs direct cheque/card) only suggested, not changed. Order: accountant pick/lock > accountant learned decision > history > AI name guess. Approval still required (PushGate). Own flag, off. Step 1 = measurement on BBMS history (consistency per vendor of account, funding, cycle) BEFORE any pick logic; then tests, build, measure on BBMS pending rows (how many "ambiguous" flags disappear).
- Amin's framing: the goal is that rows arrive as if an accountant's assistant entered them; the accountant only reviews/approves; corrections then feed the existing learning.

REMAINING (audit order; phase 2 BUILT 2026-10-21, awaiting merge + prod dry run):
- 2 QBO read-only backfill + sync (history_qbo_sync, per company; needs 0c 429 handling).
- 4 company profile (schema 5.4 of the design review; needs the accounting team's answers).
- 5 learned patterns + bulk confirm (learned_patterns).
- 6 the rest of resolver integration: PROFILE and PATTERN sources, tax resolver, recurring matcher.
- 7 settlement workflow (structured settlement read + reconciler; replaces unshipped c023522).
- 8 rollout pilot → firm → all, weekly measurement.

Side items seen 2026-10-20, not built: chart account names stored with wrong encoding ("64901 � School Supplies"); "split across these accounts" label for multi-account entries (paycheques); QBD Customers cycle (Receive Payment → Undeposited Funds → Record Deposit) to inform the AR deposit-slip design ([[ar-accountant-workflow-questions]]).

**Why:** Amin asked (2026-10-20) not to lose track of which phases are done and which remain.
**How to apply:** at the start of history-related work, read this; after each checkpoint, move the item and update the line in MEMORY.md.

2026-10-20 PROD: cp-315 deployed (127de8e, migration 000004 ran). Dry run on BBMS company 11: 28 pending rows; ACCOUNT_AMBIGUITY 18 -> 11 answered; FUNDING_ACCOUNT_AMBIGUOUS 6 -> 4 answered, 2 wait for card ...7852. ACCOUNTING_V2_HISTORY_DECISIONS=true set on prod .env and --apply run (same numbers). Pending: Amin links card 7852 on the history page + reviews drawers.

2026-10-20 review of applied rows: Amazon #2058 got 64900 Office Supplies (1 of 135) via the document rule; Intact #2063 kept GIFI 9810 (farm) because Expense/Insurance maps to 8690 + 3 farm codes and derive returned null. Fixes on branch work/phase4-document-rule-20261020 = validation/... (document rule needs >= min_entries; applier rewrites gifi_decision; GifiFromAccount uses CanadianChartOfAccounts::gifiForSubtype when several codes share a subtype). CI green (SQLite 2721, PG 2398). NOT merged: awaiting Amin for cp-316; after deploy run history:decisions 11 --apply again and ai:extraction-check --runs=3 (GIFI change).
MERGED 2026-10-20: main = 5cf67da = checkpoint-316, pushed from the laptop; server pull + history:decisions 11 --apply + ai:extraction-check PENDING.
2026-10-20 after cp-316 on prod: Amazon #2058 fixed (School Supplies 122/135, GIFI 8811); Intact #2063 still 9810 because the applier rewrote GIFI only on account change. Fix on work/phase4-gifi-refresh-20261020 = validation/... (CI green SQLite 2721, PG 2398), NOT merged, awaiting Amin for cp-317. Amin has not yet sent the --apply and ai:extraction-check outputs of cp-316.
MERGED 2026-10-20: main = checkpoint-317 (GIFI refresh), pushed from the laptop. Prod run on 5cf67da showed FUNDING_ACCOUNT_AMBIGUOUS 0 left (card 7852 linked by Amin), ACCOUNT_AMBIGUITY 7 left (not clear in history).
VERIFIED 2026-10-20: cp-317 (d34352d) live; Intact GIFI 8690; --apply rewrote 2 GIFI lines; ai:extraction-check --runs=3 18/18, 0 false automatic decisions. Phase 4 core DONE, ACCOUNTING_V2_HISTORY_DECISIONS=true on prod. BBMS: FUNDING_ACCOUNT_AMBIGUOUS 0 left, ACCOUNT_AMBIGUITY 7 left (history not clear). NEXT (Amin: go with your proposal): 1 recording cycle as a suggestion only, 2 chart name encoding, then audit phases 2,4,5,6,7,8.
2026-10-20: cycle suggestion (93d7062) + U+FFFD display fix (a09eecb) on work/history-cycle-suggestion-20261020 = validation/..., CI green (SQLite 2722, PG 2399), NOT merged, awaiting Amin for cp-318. The U+FFFD comes from QuickBooks itself (BBMS chart migrated from QBD), display-only fix.
MERGED 2026-10-20: main = checkpoint-318 (cycle suggestion + U+FFFD display), pushed from the laptop; server deploy PENDING.
VERIFIED 2026-10-20: cp-318 (a09eecb) live; cycle suggestion shows on BBMS rows (Enbridge/Yummy bill, Uber/Amazon direct, Intact amber: books paid Intact by cheque 12/12, row is a bill); '·' shown. Seen, not built: Uber's GIFI derived from account 'Transportation' is 9275 Delivery/freight (taxi rides are travel, 9200): GifiFromAccount name mapping to review.
PHASE 2 BUILT 2026-10-21: QBO history read (General Ledger per month -> Desktop-layout rows -> same parser), branch work/phase2-qbo-history-20261021 = validation/... df3bf9f, CI green (SQLite 2729, PG 2399). Flag ACCOUNTING_V2_HISTORY_QBO_READ (off), budget ACCOUNTING_V2_HISTORY_QBO_MAX_READS 40. Cross-source overlap guard: commit 409 when the company already has active history of another source in the period (BBMS has QBD 2025-08..2026-07). Real report layout NOT yet verified: plan = merge cp-319 flag off, then 'php artisan history:read-qbo 11 --from=2026-08-01 --to=2026-08-31' dry run on prod. NOT merged.
