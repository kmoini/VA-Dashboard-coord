---
name: accounting-team-qbo-complaints
description: "2026-09-21 - the accounting team's 3 complaints about the QBO work, all fixed locally (account-type list, GIFI totals, pages with no entry). Read before account-type mapping, GIFI pickers or the multi-page PDF split."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-22T00:46:19.747Z
---

The accounting team (testing on production) raised three complaints on
2026-09-21 about the QuickBooks work. All three are fixed and committed locally
on `main`, each with a `docs/*-2026-09-21.md` and a test.

1. **Account-type mapping was not standard.** The list came from
   `App\Accounting\Enums\AccountType`, written for Bigcapital: it offered "Cash"
   and "Inventory" (not QuickBooks types) and omitted "Other Current Asset".
   Fixed: the list is now `QuickBooksVocabulary::types()` (the mappable ones),
   spelled as QuickBooks spells them; migration `2026_09_21_000003` re-keys
   stored mappings; accounts list by `FullyQualifiedName`.
   ⚠️ Do NOT delete Cash/Inventory from `AccountType`, they are correct for
   Bigcapital; `toQbo()` is the bridge and two cases map to `Bank`.

2. **⚠️⚠️ The GIFI pickers had WRONG LABELS, which is probably most of what
   looked like confusion.** Three screens each hard-coded a "common codes"
   array. Transactions/Index said 8690 was "Travel Expenses" (CRA 8690 is
   Insurance) and 8710 "Meals and Entertainment" (8710 is Interest and bank
   charges); Transactions/Create said 8860 was "Amortization" (8860 is
   Professional fees) and 8810 "Rent" (8810 is Office expenses), and the two
   screens disagreed about 8000. Separately, a GIFI total was refused only at
   PUSH time. Fixed: `App\Accounting\GifiCatalog` + `App\Rules\PostableGifiCode`
   + `GET /gifi-codes` + `lib/gifiCatalog.js` + `GifiCodeDatalist`. Nothing
   auto-corrects; an unknown code is not refused; the learning loop no longer
   trains on totals.

3. **17 of 18 pages went to "Documents with no entry".** A multi-page PDF is
   split into one JPEG per page and each page goes to the model alone, so later
   pages of an invoice (contract terms, breakdowns) produce nothing. Fixed:
   `DocumentAiIngestService::attachOrphanPages()` puts such a page on the entry
   its own document produced, but ONLY when the document produced exactly one
   entry (a scan batch of receipts must not be guessed at).

**⏭️ STILL OPEN, owner's call:** one AI call per document.
`MultiPageDocumentGrouper` + `ingestCombinedDocument()` already exist and are
unreachable only because the grouper decides from OCR text and the split pages
are JPEGs with `OCR_ENABLED=false`. `pdftotext -f/-l` would give per-page text
on any digital PDF without OCR, and poppler is already installed wherever the
split runs.

Related: [[document-role-triage]], [[gifi-qbo-account-mapping]],
[[international-quickbooks]], [[ai-prompt-registry]], [[document-ai-pipeline]],
[[local-test-before-push]].
