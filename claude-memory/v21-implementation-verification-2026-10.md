---
name: v21-implementation-verification-2026-10
description: 2026-10-07 read-only V2.1 architecture verification (for the architect AI), PDF in Downloads; verdict YELLOW with P0/P1 lists. READ before planning the next V2 work.
metadata:
  type: project
---

Report: C:\Users\Amin\Downloads\VoiceAccountant-V2.1-Implementation-Verification-2026-10-07.pdf (HTML source in the session scratchpad only; nothing in the repo). Made at va-dashboard2 main 6a64052 (checkpoint-279) from five parallel read-only code sweeps.

Verdict YELLOW. Implemented: full pipeline for every intake path, event model (31 codes), review dimensions, settlement lifecycle, loans, deposits, DuplicateMatcherV2, decision provenance, flags, event-aware QBO posting. NOT implemented: account-first inversion (GIFI still decided first, account searched from GIFI; DecisionSource::QBO_ACCOUNT never assigned), chart never shown to the model, no UI to pick among account_candidates.

P0 (engine is live for all firms): clear chosen_account_external_id when GIFI/category is edited; lock dimensions on approve (recordConfirmation locks nothing); guard QuickBooksPushService::recategorize, TransactionService::merge, MobileTransactionProjector refresh (amount/description/date); restrict ai_feedback_signals + GifiLearningService to accountant actors and drop the global cross-firm GIFI layer; paginate QboAccountSnapshotService (maxresults 1000, inactivates unseen); use forClient at the posting gate (LedgerEntryDTO:100, BusinessEventResolver:133).
P1: candidate picker; derive GIFI from the chosen account for QBO clients; RequestId on on-account BillPayment/updates/createParty; party token with to_party; snapshot refresh on connect; equity-event GIFI band; prompt_version; tests (e2e ingest→push, email/portal with V2 on, recode→rerun→push, snapshot refresh).
Policy open: per-person labour lines on one receipt (prompt says ONE row per receipt); per-client AP never-invoices list.

**Why:** the architect asked for proof of distance from the target before allowing more implementation; Amin wants no code changed by that audit.
**How to apply:** when Amin says continue V2, start from the P0 list above; cite the PDF sections. Related: [[accounting-v2-phase4-status]], [[v2-architecture-audit-2026-09]], [[never-overrule-the-accountant]].
