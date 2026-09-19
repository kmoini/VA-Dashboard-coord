---
name: international-quickbooks
description: "SHIPPED cp-242 (2026-09-17): Britain and Australia verified end to end. ⚠️⚠️ EVERYTHING used to assume Canada silently. A tax code belongs to a COUNTRY (AU and CA both have one named GST, 10% vs 5%) and to a SIDE (AU purchases and sales use different codes). ⚠️ tax_amount must always be the same currency as amount. READ before QuickBooks, tax codes, currency, client creation or anything per-country."
metadata:
  type: project
  node_type: memory
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-18T19:56:26.714Z
---

Full write-up: `docs/INTERNATIONAL-QUICKBOOKS.md`. Verified live on real
documents: Canada `Bill/186 188.18/21.65/166.53`, Britain
`Purchase/184 12.70/2.12/10.58 GBP`, Australia
`Purchase/198 160.40/14.58/145.82 AUD`, United States `Purchase/175 22.92 USD`
(cp-243: a Walmart receipt, subtotal 21.42 + tax 1.50, posted the TOTAL as one line).

## ⚠️⚠️ The shape of every bug in this arc

A value correct in Canada is accepted somewhere it means something different,
the arithmetic still works, and every screen looks reasonable. No exception ever
threw. Look for this shape first.

## The load-bearing facts

- `quickbooks_connections.country` (Intuit's alpha-3) is the key everything
  per-country hangs off. NULL means "never asked", NEVER "assume Canada".
- ⚠️ Intuit sends `CA` where its own docs say `CAN`. `App\Accounting\CompanyCountry`
  normalises both ways from ONE table. Every locale column is alpha-3 now.
- ⚠️⚠️ A tax code belongs to a COUNTRY: `TaxCodeVocabulary::forCountry()`. Ours is
  `GST_AU` for Australia and can never be `GST`, which is Canada's 5%.
- ⚠️⚠️ And to a SIDE: `tax_code_purchase` / `tax_code_sales` mapping types. AU's
  `GST` has a sales rate only, `GST on non-capital` a purchase rate only; using
  the wrong one is QBO error 6000 "error while calculating tax". Plain `tax_code`
  still means both sides and is the fallback (CA and GB codes carry both rates).
- ⚠️ The USA splits NO tax by design: its purchase tax is part of the cost, so
  the tax fields are removed from the extraction schema (Gemini rejects an empty
  enum).
- ⚠️⚠️ `tax_amount` is always the same currency as `amount`. `original_tax_amount`
  keeps the printed figure. A £12.70 receipt posted as £25.79 because conversion
  moved the amount and not the tax, and that was never British: any Canadian
  client's USD receipt with tax had the same mix.
- A client's base currency: their own setting, then their QuickBooks company's
  home currency, then the firm default. Everything goes through
  `BaseCurrencyResolver`; six copies of that rule were deleted.
- Country is REQUIRED when creating a client, through every door including the
  invitation, and QuickBooks fills in what was never asked (empty fields only, a
  disagreement is reported not overwritten).

## ⚠️ Traps that cost hours

- Prompt changes need a publish migration; `PromptPublishGuardTest` pins five
  hashes. See [[ai-prompt-registry]].
- `activity_logs` CHECK shipped a bug a SIXTH time, on `action_source` (the
  column with no guard). All three columns are test-scanned now. See
  [[activity-log-entity-type-trap]].
- A company's Preferences were cached forever, so code added later (homeCurrency)
  never appeared. Now aged out at 7 days AND checked for shape.
- `qbo_subtype_locales` records SIGHTINGS only. Absence is never a refusal.
  USED since cp-245 (2026-09-18; UI path not live-exercised, a full sandbox chart auto-matches before Choose account appears): `SubtypeEvidence` decides
  the create-account warning per country; accepted creates record a sighting.
  ⚠️ Never hard-code a country name in UI copy; the server sends `subtype_note`.
- ⚠️ QBO query language escapes `'` with a BACKSLASH, not SQL doubling: `Sainsbury''s`
  got HTTP 400 so apostrophe vendors never pushed (fixed cp-245, live-verified).

Related: [[sales-tax-hst-gst]], [[quickbooks-push-idempotency]],
[[gifi-qbo-account-mapping]], [[checkpoint-rule]].
