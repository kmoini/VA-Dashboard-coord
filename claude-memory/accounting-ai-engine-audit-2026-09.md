---
name: accounting-ai-engine-audit-2026-09
description: 2026-09-30 read-only audit of the va-dashboard2 document-to-QBO AI engine (15-part Claude Doc) made for Amin to discuss with another AI; lists the 17 confirmed classification weaknesses and the decisions to make before any code change.
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-01T00:33:21.452Z
---

On 2026-09-30, after the accounting team reported new Record Keeping errors, Amin asked for a read-only inspection (no code changes) of how the accounting AI engine works, to hand to another AI. The result is the Claude Doc "VoiceAccountant Accounting AI Engine: Current-State Audit"
https://claude.ai/code/artifact/03363a37-aabf-47f5-a921-d0aa7a4658c7

Key findings worth remembering (all with file:line evidence in the doc):
- ONE gemini-3.1-flash-lite call decides direction (expense|revenue only), account_type (16), category (free text from a prompt list), tax code and document_role. The AI never sees the COA, the GIFI table, past transactions or past corrections. GIFI is derived afterwards by GifiResolver keyword scoring on `category`; the QBO account is derived from GIFI at push time. No transfer / refund / unknown type exists.
- Confirmed weak points (Part 12 A1-A17): unchecked LLM direction; `direction_uncertain` never shown in UI; owner-alias loop (ClientAiContext feeds ledger corporation_names back as owner names); silent GIFI default 9270/8000; GifiLearningService keys on the vendor's FIRST WORD and overrides after 2 firm overrides, learning from portal clients too; GifiAccountMatcher reads the PHP GifiReference not the gifi_codes table; province inferred from the vendor address, unknown country falls to CAN, email path has no country; validator drops tax silently; $500 capitalisation is prompt text only; funding account falls back to first Bank account; `recategorize`, learned fills and mobile projector write with saveQuietly (no audit, mobile overwrites pending manual rows); RuleEngine set_gifi and interco GIFI writes are no-ops; portal clients have full edit/approve/GIFI rights despite comments saying read-only.
- Unknowns: active prompt version in ai_prompt_versions vs shipped .txt; prod OCR env flags; actual ai_feedback_signals contents.

**Why:** the team is about to decide how to raise classification accuracy; the doc is the agreed baseline of what exists today.

**How to apply:** before proposing any classification/GIFI/tax change, read the doc's Part 12 and Part 15 M (investigation order: classify the real errors by type and intake path first). Do not re-run the full code sweep; update the doc instead. Related: [[gifi-codes-table-not-file]], [[ai-prompt-registry]], [[extraction-measurement-harness]], [[never-overrule-the-accountant]], [[sales-tax-hst-gst]], [[gifi-qbo-account-mapping]], [[quickbooks-push-idempotency]].
