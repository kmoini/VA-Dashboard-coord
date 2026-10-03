---
name: accounting-v2-phase2-status
description: "Accounting V2 phase 2 (one draft contract for manual/portal/mobile/voice/email intake via IntakeDraftService, accountant entries locked at creation, business_event in the extraction schema, TaxDecisionResolver, one-document-many-transactions siblings) BUILT LOCALLY 2026-10-01 after checkpoint-265, flags off by default, NOT pushed, waiting for Amin's local test. READ before phase 3 or touching any transaction create site."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-02T17:24:18.407Z
---

Built 2026-10-01 evening on `main` after checkpoint-265 (local commit, not pushed). Guide: `docs/ACCOUNTING-V2-PHASE2.md`. Design basis: [[v2-architecture-audit-2026-09]], builds on [[accounting-v2-phase1-status]].

**What exists:** `app/Accounting/V2/IntakeDraftService` (draft / attributes / record / protectedColumns; actors accountant|client|mobile|ai) wired into `TransactionService::create`, `ClientPortalController::storeTransaction`, `MobileTransactionProjector` (create + refresh skips locked columns), `MobileVoiceIntakeController`, `InboundEmailService::createDraft` (+ `foldInto` skips locked columns, `draftsOf` validates per client country). `TaxDecisionResolver` (flag TAX_DECISION_V2_ENABLED; event → no-tax code, arithmetic → rate → code, `clients.region` → home code; never touches amount). Extractor: `business_event` + confidence REQUIRED enum in the schema and `document-extraction.event` fragment appended to the dynamic tail when EVENT flag on (via `ClientAiContext` keys `v2_events`/`v2_multi`); `document-extraction.multi` fragment + sibling exclusion in `persistDrafts` + `ai_provenance.row_index` when MULTI_TRANSACTION_DOCUMENT_ENABLED. `TransactionDecisionRecorder::recordDraft` records human sources/locks from `CanonicalDraft::decisionSource/humanLocked/actorUserId`. `DuplicateMatcherV2::evaluate(..., $excludeIds)`. Tests: `tests/Feature/AccountingV2` = 72 (phase 1 + 2). No new migrations.

**Gotchas:** `TaxCodeVocabulary::codesFor` returns a LIST, `forCountry` the code=>label MAP (cost one red run). Prompt fragments go in the dynamic tail on purpose: the main templates may be DB-overridden on prod ([[ai-prompt-registry]]) and a new {{token}} would be silently ignored. `MULTI_TRANSACTION_DOCUMENT_ENABLED` has no `_V2` in its env name. Tinker hangs on this Windows box; read local Postgres with Laragon psql.

**Why:** Amin said "فاز ۲ را شروع کن" after approving and deploying phase 1; the audits' first recommendation was one draft contract for all intake paths.

**Local test 2026-10-02 (Amin) passed** on manual form, duplicate, receipt onto a manual row, multi-line statement, e-Transfer, and found 3 bugs fixed the same day (3869561, 1a15add: human rows never rewritten by the tax resolver; receipt fills the row's own tax decision; rule-decided tax reaches the row). Also added: icon-only + button in Record Keeping and tax fields on the manual form (e75394d, 5b1f72c). Amin said OK to push on 2026-10-02 → checkpoint-266 commands handed to him (auto-mode blocks git push). Open item: [[open-question-etransfer-without-bill]]. Agreed next: phase 2.5 (bank statement → statement lines + matching, NOT ledger rows), then phase 3.

**How to apply:** checkpoint (next number from live `git tag`) + push only when he says so. Before enabling the EVENT flag for the accounting team on prod, run `ai:extraction-check --runs=3` on the server ([[extraction-measurement-harness]]): a new required enum can shift the model's other answers. Then phase 3 (QBO event-based mapping, snapshot-driven account selection) and phase 4 (settlement lifecycle).
