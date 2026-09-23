---
name: accounting-team-qbo-complaints
description: "2026-09-21/22 - the accounting team's 3 complaints about the QBO work. Complaint 1 (account types) is PAUSED awaiting their written spec; 2 and 3 fixed. Read before account-type mapping, GIFI pickers, extraction prompts or the multi-page PDF split."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-22T16:30:30.264Z
---

The accounting team (testing on production) raised three complaints on
2026-09-21 about the QuickBooks work. Each fix has a `docs/*-2026-09-2*.md` and
a test. Nothing is pushed yet; Amin decides when.

**1. Account-type mapping ⏸️ PAUSED.** Amin re-read my fix on 2026-09-22 and
said it still does not match what the team sees; he has asked them for a
written standard description and will pass it on. ⚠️ DO NOT GUESS FURTHER, wait
for that document. What shipped locally (`2fb583a`): the list now comes from
`QuickBooksVocabulary::types()` with QuickBooks' own spelling, migration
`2026_09_21_000003` re-keys stored mappings, accounts list by
`FullyQualifiedName`. ⚠️ Do NOT delete Cash/Inventory from `AccountType`, they
are correct for Bigcapital; `toQbo()` is the bridge and two cases map to `Bank`.
Amin also pointed at `Chart.xlsx` in his Downloads, the accountants' own chart.

**2. GIFI ✅, and I got it backwards the first time.** Two separate things:
  - ⚠️⚠️ THE PICKER LABELS WERE WRONG. Three screens hard-coded their own
    "common codes" and disagreed with CRA and each other: 8690 read "Travel"
    (CRA 8690 is Insurance), 8710 read "Meals" on one screen and "Salaries" on
    another (it is Interest and bank charges), 8860 read "Amortization" (it is
    Professional fees) and 8810 read "Rent" (8810 is Office expenses). Picking
    travel filed insurance. Fixed with
    `App\Accounting\GifiCatalog` + `GET /gifi-codes` + `lib/gifiCatalog.js` +
    `GifiCodeDatalist`, one list read from `gifi_codes`. THIS PART STAYS.
  - ⚠️⚠️ I ALSO ADDED A BLOCK ON GIFI TOTALS, WHICH WAS THE OPPOSITE OF THE
    ASK, and removed it the next day in `e53b9e4` along with the older
    push-time refusals. See [[never-overrule-the-accountant]].

**3. Documents never reaching the ledger ✅, two causes.**
  - Pages of a multi-page PDF with no amount (contract terms, breakdowns) went
    to "Documents with no entry". `DocumentAiIngestService::attachOrphanPages()`
    now puts them on the entry their own document produced, but ONLY when that
    document produced exactly one entry (a scan batch of receipts must not be
    guessed at). Commit `c5b799b`.
  - ⚠️ REAL INVOICES WERE CLASSIFIED `supporting`. A file named "Yummy Invoice
    $5,993.57.pdf" came back as "statement of account showing balance due, not
    an invoice itself". The prompt listed "statement of account" flatly under
    supporting, had no cue protecting a page headed Invoice, and the "when two
    roles fit choose the NON-postable one" tie-break settled it. Fixed in both
    extraction prompts + publish migration
    `2026_09_22_000001_publish_invoice_is_a_source_document`, pinned by
    `tests/Unit/InvoiceIsASourceDocumentPromptTest.php`.
    ⚠️ The prompt now also says a non-postable document must STILL be read into
    the array: returning nothing is why the drawer showed "Nothing readable in
    this file" with no amount or party to judge by.

**⏭️ STILL OPEN, owner's call:** one AI call per document.
`MultiPageDocumentGrouper` + `ingestCombinedDocument()` already exist and are
unreachable only because the grouper decides from OCR text and the split pages
are JPEGs with `OCR_ENABLED=false`. `pdftotext -f/-l` would give per-page text
on any digital PDF without OCR, and poppler is already installed there.

Related: [[never-overrule-the-accountant]], [[document-role-triage]],
[[gifi-qbo-account-mapping]], [[international-quickbooks]],
[[ai-prompt-registry]], [[document-ai-pipeline]], [[local-test-before-push]].
