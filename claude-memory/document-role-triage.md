---
name: document-role-triage
description: "Cheque copies / pay stubs / quotes no longer become transactions — document_role gate + Record Keeping review drawer. Built 2026-08-09, NOT deployed. Read before extraction prompts, DocumentAiIngestService, or attachment triage."
metadata: 
  node_type: memory
  type: project
  originSessionId: 2cb1ed71-a29a-48cd-885e-2494e25660fc
  modified: 2026-08-10T01:14:57.427Z
---

Built 2026-08-09 on `va-dashboard2`, **local only, NOT deployed**, awaiting Amin's
manual test. Full record: `docs/document-role-and-triage.md`. Persian test guide:
`docs/document-triage-test-guide-fa.md`.

**Root cause worth not re-deriving:** the extraction prompt itself said "a document
with an amount and a vendor IS a transaction and MUST be extracted". So printed
cheques, remittance stubs and pay slips each became a `pending` expense — double
counting the invoice they settle. `TransactionDraftValidator` only ever rejected
`amount <= 0`; there was no concept of "not a ledger event" anywhere in the code.

**Shape:** new top-level `document_role` on the extraction response schema (REQUIRED,
enum) → `App\Services\Documents\DocumentRole`. Only `source_document` is postable;
`payment_advice` / `payroll_document` / `supporting` / `non_financial` are held back.
**`null` role is POSTABLE on purpose** (fail-open for old rows and unclassified paths).
Second judge = `DocumentRoleDetector`, a deterministic keyword pass that can only move
postable → non-postable (CHQ.#, "and 00/100 Dollars", "Amt. Paid", Net Pay + Total
Gross, CPP + EI). Payroll is tested BEFORE cheque markers — a payroll cheque has both.

**Traps solved (do not undo):**
- The checksum replay (`tryReuseByChecksum`) has no model verdict and no text, so the
  role is stored INSIDE `ai_extract_raw` and travels with the bytes. Without it a
  re-uploaded cheque gets booked on the second upload.
- Reading ≠ booking: held-back documents are still fully extracted, because the
  amount/date/party is what makes the review queue actionable and what "book it
  anyway" replays with no second Gemini call.
- `holdBack()` runs `findMatch()` and AUTO-LINKS an unambiguous match, so a cheque for
  an invoice already in the books never reaches a human.
- New `ai_extract_status` value `not_a_transaction`, distinct from `no_transactions`
  ("found no amount").
- Audit uses entity_type `Attachment` + action `updated`, both already in the CHECK
  allow-lists — no new value, see [[activity-log-entity-type-trap]].
- Fixed in passing: `persistDrafts` called `pg_advisory_xact_lock` unguarded, making
  the whole persist path untestable on the SQLite test connection.

**Amin's decisions 2026-08-09:** pay stubs are non-postable (any single-line reading of
one is wrong); unpaid estimates non-postable but a PAID stamp / Balance Due 0.00 makes
it a source document; the queue is scoped to client only, NEVER to the ledger's date
filters; existing wrong transactions are NOT cleaned up (pre-launch, no real clients).

**Deploy owes:** `migrate --force`, `npm run build`, `optimize:clear` (5 new routes),
`queue:restart`, and `php artisan document-ai:clear-cache` (the schema changed; stale
cached readings would be replayed).

⚠️ The suite has ~52 PRE-EXISTING failures in this checkout (`database/factories/`
does not exist → `Class "Database\Factories\UserFactory" not found`, plus M2M,
Bigcapital, Community, RuleEngine). 17 new tests pass. Don't chase those 52.

Related: [[document-ai-pipeline]], [[ai-prompt-registry]], [[document-hub-folders]],
[[books-accounting-overhaul-plan]], [[wait-for-user-test-before-deploy]].
