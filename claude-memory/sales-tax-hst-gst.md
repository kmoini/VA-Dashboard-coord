---
name: sales-tax-hst-gst
description: "SHIPPED 2026-09-08/09: HST/GST is extracted, mapped per QBO company, shown and editable. ⚠️⚠️ tax_amount is INSIDE amount, never added; TransactionDraftValidator drops bad tax and NEVER moves the amount (Amin's condition). ⚠️⚠️ 2026-09-23: tax+date were OPTIONAL in the Gemini schema and flash-lite simply skipped them, so every document pushed as Out of Scope; they are REQUIRED now with an explicit way to say none. ⚠️ prompt changes need a publish migration. READ before extraction prompts, tax, ITC, or QuickBooks TaxCodeRef work."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-23T23:12:26.950Z
---

Built 2026-09-08/09 in four phases, after the GIFI to QuickBooks work
([[gifi-qbo-account-mapping]]) exposed that Canadian pushes sent one gross
figure with no tax split at all.

## The state it replaced

The chain was broken at every link, not just the last:

1. The extraction prompt said **"include tax in the total; do not split tax"**,
   so `transactions.tax_code` and `tax_amount` were null on all 28 production
   transactions. The columns had existed unused since 2026-08-06.
2. `IntegrationMapping::TYPE_TAX_CODE` was READ in one place
   (`QuickBooksReferenceResolver::taxCodeFor`) and **written nowhere**: no
   screen, no command, no import. Setup was impossible, not merely skipped.
3. So `TaxCodeRef` was never set and no accountant could claim an input tax
   credit from these books.

## ⚠️⚠️ The invariant, which was Amin's condition for the whole feature

`tax_amount` is **part of** `amount`, never added on top.

⚠️⚠️ QuickBooks is NOT told so with `TaxInclusive`. That was tried and it posted
188.18 as 212.64: QBO ignores our total, treats the gross line as the base and
adds the code's rate on top. Lines go **NET** with `GlobalTaxCalculation:
TaxExcluded` (or `NotApplicable` when no line carries a tax code), and QBO
rebuilds the document total. Netting happens ONLY when a tax code resolved; with
no code we send the gross and claim no tax. See [[quickbooks-push-idempotency]].

His worry, correctly: a model asked to split the tax starts reporting the
pre-tax SUBTOTAL as the amount, and every ledger row quietly shrinks.

So the guard is a **rule, not a request**. `TransactionDraftValidator` has NO
branch that adjusts the amount for tax. Five ways a draft loses its tax, each
leaving the amount untouched: unknown code, nil-rated code carrying a figure,
non-finite or negative figure, tax not strictly less than the amount (the swap),
and a share above `TaxCodeVocabulary::MAX_TAX_RATIO` (0.30). A missing tax split
is a gap somebody fills in; a wrong amount is a wrong ledger nobody notices.

Guarded at three levels: `SalesTaxExtractionSchemaTest` pins the amount sentence
verbatim, `SalesTaxGuardTest` proves the swap case, and the validator enforces
it whatever the model says.

## Shape

- `App\Accounting\TaxCodeVocabulary` — 13 codes, labels only. ⚠️ **NO RATES**:
  they change (Nova Scotia moved its HST in 2025) and `transactions.tax_rate`
  exists to hold what was ACTUALLY charged, from the document. ZERO and EXEMPT
  stay separate because a return keeps them separate.
- `QuickBooksTaxCodeMatcher` — suggests a company's code for each of ours.
  ⚠️ Subset matching alone was wrong: our `GST` is a subset of "GST/PST BC", so
  a company with no standalone GST code matched the combined one, which is a
  different amount on a return. Now a candidate may carry no SIGNIFICANT token
  we did not ask for. `isNilRatedName()` blocks mapping a taxable code to
  Exempt, which Amin did and nothing objected to.
- Mapping UI on `/accounting`, saved as `TYPE_TAX_CODE`, once per company (most
  need 1 to 3 rows, not 13).
- Tax and Tax amount are optional columns in Record Keeping, with a "Sales tax"
  preset. The code is a SELECT because a hand-typed `HST-ON` saved fine and then
  matched nothing forever.

## ⚠️ Prompt changes need a publish migration

`AiPromptRegistry` resolves the DB override first, so editing
`resources/ai-prompts/*.txt` changes nothing on production. `PromptPublishGuardTest`
pins a hash of the shipped file and fails the build until a publish migration
ships in the same commit (pattern: `2026_09_08_000003_publish_sales_tax_extraction_prompts`).
It caught this change. The batch prompt gets the byte-identical block, generated
from the extract one, or Economy Batch documents silently carry no tax.

## ⚠️⚠️ 2026-09-23: tax was never ANSWERED, and "optional" was why

Tax used to be OPTIONAL in the Gemini response schema, reasoning that requiring
it would make the model invent tax on documents that carry none. That reasoning
cost every row: flash-lite skips optional fields, so `tax_amount`, `tax_code`
AND `effective_date` came back **absent** (not null, not 0) on six consecutive
real documents, including a scanned invoice printing `HST 19.50` on its face.
All six reached QuickBooks as "Out of Scope of Tax" with nothing saying so, and
the missing date meant the row was silently stamped with today.

⚠️ Three earlier runs of the real extractor looked like model nondeterminism
(1 in 3 returned tax). That reading was WRONG. Do not diagnose a missing field
as flakiness before checking whether it is in `required`.

The fix: `tax_code` + `tax_amount` + `effective_date` are REQUIRED, with an
explicit honest escape, `OUT_OF_SCOPE` / `NO_VAT` / `GST_FREE` plus amount 0,
and `""` for a dateless document. `tax_rate` stays optional (a printed rate has
no "none" to state). After it: 3 runs of 3 returned HST_ON 19.50; a PD7A and an
e-transfer answered OUT_OF_SCOPE / 0. Safe because the validator still drops a
named code with no figure and never moves the amount. Full write-up:
`docs/sales-tax-was-never-answered.md`.

⚠️ Existing rows do NOT gain the tax: a re-read links back to the transaction
rather than overwriting a row the accountant may have edited.

## Open

- ✅ Live-verified end to end 2026-09-09 on CA realm `9341457870284884`:
  `Bill/186 TotalAmt=188.18 TotalTax=21.65 line=166.53`, from a real supplier
  bill. Extraction gave the gross figures (188.18 / 146.34), not the net ones.
- ✅ cp-244 (2026-09-18): the document's tax is PINNED as `TxnTaxDetail.TaxLine`
  with a `TaxRateRef` (probed first with `quickbooks:probe-tax-override`: QBO
  keeps it; TotalTax alone is IGNORED). ⚠️⚠️ Without it a MIXED-RATE receipt
  (zero-rated groceries + taxed items) posted the full rate on the whole net line,
  a wrong TOTAL. Live: Maple Market 33.01 / HST 2.08 posted 33.01 (else 34.95).
  Pinned only when one code, one rate on that side, and tax NOT above rate x line.
- Existing transactions gain nothing retroactively.
- No firm-level default tax code yet (would help a firm whose clients are all in
  one province, mirroring the GIFI firm override).
