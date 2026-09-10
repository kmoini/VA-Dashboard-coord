---
name: sales-tax-hst-gst
description: "SHIPPED 2026-09-08/09: HST/GST is extracted, mapped per QBO company, shown and editable. ⚠️⚠️ tax_amount is INSIDE amount, never added; TransactionDraftValidator drops bad tax and NEVER moves the amount (Amin's condition). ⚠️ prompt changes need a publish migration. READ before extraction prompts, tax, ITC, or QuickBooks TaxCodeRef work."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-09T21:05:54.937Z
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

⚠️ The tax fields are OPTIONAL in the Gemini response schema. Everything else is
`required` because flash-lite skips optional fields; here that pressure would
make it invent tax on documents that carry none.

## Open

- ✅ Live-verified end to end 2026-09-09 on CA realm `9341457870284884`:
  `Bill/186 TotalAmt=188.18 TotalTax=21.65 line=166.53`, from a real supplier
  bill. Extraction gave the gross figures (188.18 / 146.34), not the net ones.
- ⚠️ QBO computes the tax from the mapped code's RATE, so a document whose tax is
  a cent or two off the arithmetic posts the arithmetic. Pinning the printed
  figure needs `TxnTaxDetail.TaxLine` with a `TaxRateRef`, not yet built.
- Existing transactions gain nothing retroactively.
- No firm-level default tax code yet (would help a firm whose clients are all in
  one province, mirroring the GIFI firm override).
