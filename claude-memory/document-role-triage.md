---
name: document-role-triage
description: "SHIPPED cp-221/222/223 — document_role keeps cheque prints, pay stubs, quotes, contracts and CREDIT NOTES out of the ledger, plus the Record Keeping review drawer. Read before extraction prompts, DocumentAiIngestService, GIFI keywords, or attachment triage."
metadata: 
  node_type: memory
  type: project
  originSessionId: 2cb1ed71-a29a-48cd-885e-2494e25660fc
  modified: 2026-08-11T15:34:10.769Z
---

**SHIPPED to production 2026-08-10/11** as checkpoints 221, 222, 223. Full record:
`va-dashboard2/docs/document-role-and-triage.md`. Persian test guide:
`docs/document-triage-test-guide-fa.md`. Verified on prod with real client documents.

**Root cause, do not re-derive:** the extraction prompt itself said "a document with an
amount and a vendor IS a transaction and MUST be extracted". So cheque prints, pay slips
and a 47-page lease each became a `pending` expense. `TransactionDraftValidator` only ever
rejected `amount <= 0`; nothing in the code held the idea "not a ledger event".

**Shape:** top-level `document_role` on the extraction schema (REQUIRED, enum) →
`App\Services\Documents\DocumentRole`. Postable: `source_document` only. Held back:
`payment_advice`, `payroll_document`, `supporting`, `credit_note`, `non_financial`.
⚠️ **NULL role is POSTABLE by design** (fail-open for old rows/unclassified paths).
Second judge = `DocumentRoleDetector`, deterministic keywords, can only move postable →
non-postable. Held-back docs are still fully READ (amount/date/party feed the drawer and
"book it anyway"), auto-link to a matching entry via `findMatch`, and land in the Record
Keeping "N documents, no entry" drawer (attach / book anyway / keep as document).

**⚠️⚠️ THE TRAP THAT COST A WHOLE SESSION:** editing `resources/ai-prompts/*.txt` does
NOTHING on production — `AiPromptRegistry` resolves the DB override first, silently, no
error. cp-221 shipped the prompt in the file while the schema (PHP) deployed, so the model
was forced to answer a field nobody had explained and guessed from enum names. **Prompt
changes now ship as a MIGRATION** (`2026_08_11_000002`, pattern from `2026_07_30_110000`).
Never go back to file-only edits. See [[ai-prompt-registry]].

**Same file-vs-DB shape for GIFI keywords:** they live in the `gifi_codes` TABLE seeded
from `GifiReference` by migration. Editing the reference alone changes nothing.

**Other findings worth keeping:**
- A negative total used to be resolved by FLIPPING THE DIRECTION: a −$282.44 Rogers credit
  became $282.44 of **revenue**. Whole class (refunds, returns, vendor credits, reversed
  fees). `credit_note` holds them; the ledger still cannot express a negative amount.
- An ISSUED cheque (bank + MICR + "PAY TO THE ORDER OF" + signature) IS a source document;
  a bare print/stub is `payment_advice`. Owner decision: for a payee who never invoices,
  the cheque is the only record.
- A cheque leaves `vendor` EMPTY (no merchant field), so the Payee column fell through to
  `corporation_name` and showed the client's own company. Validator now fills vendor from
  `to_party` (customer from `from_party`). Matters because `findMatch` keys on vendor.
- `findMatch` has a 2nd pass on **invoice_number with no date window** — a cheque dated
  2025-09-25 settling an invoice dated 11-MAY-2025 is 4 months outside the ±3-day window.
- `GifiVocabularyCoverageTest` walks the prompt's whole P&L vocabulary against the GIFI
  table. It found exactly ONE gap (9110 lacked the plural "subcontractors"), which also
  means the rest of the vocabulary is sound.
- Economy (Gemini Batch) is the DEFAULT upload mode, keeps NO document text, so the
  keyword detector is inert there and only the model judges. It also had zero test
  coverage, which is how a labelling bug shipped in it.

**Still open:** `credit_note` and `payroll_document` have no posting path (Books phase 5
already has `BooksVendorCredit`/`BooksCreditNote`; Payroll is unbuilt). A cheque with no
line items can only be coded by guess — see the People-registry backlog,
`docs/backlog-people-registry-and-cheque-rule.md` (Part 1 done, Part 2 open, 4 questions
for Amin incl. a SIN/PII decision).

⚠️ The suite has ~52 PRE-EXISTING failures in this checkout (`database/factories/` is
missing → `Class "Database\Factories\UserFactory" not found`, plus M2M, Bigcapital,
Community, RuleEngine). 27 tests for this feature pass. Don't chase those 52.

Related: [[document-ai-pipeline]], [[ai-prompt-registry]], [[document-hub-folders]],
[[books-accounting-overhaul-plan]], [[checkpoint-rule]].
