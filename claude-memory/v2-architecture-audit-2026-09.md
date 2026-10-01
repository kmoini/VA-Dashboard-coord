---
name: v2-architecture-audit-2026-09
description: "2026-09-30 read-only V2 architecture audit (Claude Doc + PDF) that validated Amin's proposed Document → Facts → Event → Direction → Account → GIFI → Tax → Validation → Review → QBO hypothesis against va-dashboard2 and recommended option A (additive evolution, explicit second side). READ before any V2 design or classification refactor."
metadata:
  node_type: memory
  type: project
  originSessionId: 7acbadfe-1c7f-4ff1-9d46-af6d92524552
  modified: 2026-10-01T02:33:14.661Z
---

Third audit in the 2026-09-30 series (after [[accounting-ai-engine-audit-2026-09]] and the Field Audit). Doc: https://claude.ai/code/artifact/a55eb7bc-34da-4ef8-930d-5304788e0d20 · PDF in C:\Users\Amin\Downloads\VoiceAccountant-V2-Architecture-Audit-2026-09-30.pdf. Field Audit doc: https://claude.ai/code/artifact/f06797ec-12a6-4bf6-9429-73d927a6deaf.

Verdict on the hypothesis: the missing layers are real (facts, business event, validation, per-field confidence/needs-review, precedents). Its inversion "QBO account first, GIFI derived" is the right destination but the code does the opposite (GIFI at draft, QBO account derived at push, chart never stored). A 5-value direction enum would break DB CHECKs, mobile mapper, QBO mapper and ~15 JSX files: derive direction from the event and keep `transaction_type` as the compat projection. `Loan` is an event, not an account type; add `other_current_asset` as the only new AccountType.

Recommendation: option A = keep `transactions` + QBO push layer; split the single Gemini call into facts + event proposal; formalise TransactionDraftValidator's `{fields, confidence, extras}` as the ONE contract for all five intake paths (Document Hub, email, mobile, voice, portal); snapshot the QBO chart and pick the account at review time from candidates; deterministic tax from facts + jurisdiction; consistency checks + review reasons instead of silent defaults; precedents keyed by vendor_id/registry entity, client scope, accountant-only, confirmed rows only; extend push with BillPayment/Payment/Transfer. No local journal now.

Prerequisites before V2 (owner must decide, section 21 lists 16 decisions): pin active prompt versions, golden-path test upload→push (none exists), close side doors (email passes no country; mobile copies GIFI raw), model-level period guard (`locked_by` column does not exist; lock() has no permission check), portal role model (clients have full edit/approve/GIFI rights despite "read-only" comments).

**Why:** the team was about to design V2 from a hypothesis; this doc is the evidence-based baseline and the agreed shape to discuss.

**How to apply:** when asked to implement any V2 piece, start from the doc's sections 16 to 19 and the migration order; never change `transaction_type`/`status`/`account_type` VALUES in place; add columns beside and project back. Re-read section 14 (20 blind spots) before scoping.
