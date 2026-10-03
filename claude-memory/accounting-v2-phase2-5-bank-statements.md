---
name: accounting-v2-phase2-5-bank-statements
description: "Accounting V2 phase 2.5 (BANK_STATEMENT_LINES_ENABLED): a statement in the Document Hub becomes bank_statement_lines for reconciliation beside the ledger (which still books only the bank's own charges, owner's Sept rule); matcher both ways; Record Keeping chip + drawer (confirm / create entry / exclude). BUILT LOCALLY 2026-10-02 after checkpoint-266, NOT pushed, waiting for Amin's local test. READ before statements, reconciliation, BankLineMatcher or the Banking tab."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-02T20:52:24.454Z
---

Built 2026-10-02 on `main` after checkpoint-266 (local commit, not pushed). Guide: `docs/ACCOUNTING-V2-PHASE2_5-BANK-STATEMENTS.md`. Follows [[accounting-v2-phase2-status]].

**Why:** Amin asked (2026-10-02) whether statements belong in Record Keeping at all and how duplicates with separately entered receipts are avoided, with reconciliation coming later. Answer built: a statement is EVIDENCE, not entries.

**What exists:** `DocumentAiExtractor::extractStatementLines` (prompt `bank-statement.extract`, signed lines, money out negative), `app/Services/Books/StatementDocumentIntake` (idempotent per attachment; stores via the existing `BankStatementImporter`, account by last4, `BankLineMatcher::suggest` per line, stamps `TRIAGE_STATEMENT_IMPORTED`), hooks `DocumentAiIngestService::statementLinesIfAny` after persistDrafts in ingestWhole / ingestCombinedDocument / ingestBatchResult, `BankLineMatcher::suggestForTransaction` (reverse: new entry finds its line; called from `recordV2` and `IntakeDraftService::record`), score bonus +0.25 "booked from this statement" (fee rows pair with their own lines without a name match), `BankLinesController` at `/recordkeeping/bank-lines` (index / candidates / resolve / create-entry), chip "N bank lines to settle" + `BankLinesDrawer.jsx` in Record Keeping, `bankLinesCount` prop. Tests `tests/Feature/AccountingV2/StatementLinesTest.php` (8). No migrations (tables from 2026-08-06).

**Gotchas / decisions:** ⚠️ the main extraction prompt's rule "A BANK OR CREDIT-CARD STATEMENT IS THE ONE DOCUMENT NOT READ LINE BY LINE" (owner's decision, pinned by `InvoiceIsASourceDocumentPromptTest`) is kept; the phase 2 `document-extraction.multi` fragment had contradicted it and was rewritten. The old Banking tab (Books/Bigcapital) is unreachable without a Bigcapital connection and is NOT used; the drawer lives in Record Keeping. Confirming a match fills `client_bank_account_id` + `funding_client_bank_account_id` on the entry when empty (clears MISSING_SOURCE_ACCOUNT). Create-entry books with `source=ai`, `ai_source=bank_feed` (allowed by the CHECK), line → `added`. Economy uploads read the file back from storage for the second pass.

**Local test 2026-10-02 (Amin, BMO statement + Google receipt) passed after 3 fixes** (ff8a9bf, 9cd1075): identical lines on one statement kept via ordinal fingerprint; tied identical fee entries from the same statement settle themselves; the human picker searches same cents up to 400 days (a receipt read a year off); the checksum REPLAY path now runs the statement hook with the cached read (`attachments.ai_extract_raw.statement_read`) and re-proposes every unmatched line of the period. ⚠️ Two reads of the same PDF can differ (second read counted the fee block 3x vs 2x); the cached read prevents drift per file; planned guard = opening + movements = closing balance check. Amin said OK 2026-10-02 → checkpoint-267 commands handed to him.

**After checkpoint-268 (local, 2026-10-02 night):** balance check built (commit 33c6d89): `reconciliation_status` balanced/unbalanced/unknown + `reconciliation_difference` + `movement_total` on `bank_statement_imports` (migration `2026_10_02_000001`, ⚠️ must be run on prod with the deploy), computed on the FULL read with bank and card sign conventions; drawer shows "does not add up by X" with **Read again** (`POST /recordkeeping/bank-lines/statements/{import}/reread`: drops the cached read, keeps matched/added/excluded lines, re-reads waiting ones, one AI call). Doc commit pending with the next checkpoint.

**How to apply:** checkpoint (next number from live `git tag`) + push only when he says so. Later: balance reconciliation (opening + movements = closing) on the import, and the open question [[open-question-etransfer-without-bill]].
