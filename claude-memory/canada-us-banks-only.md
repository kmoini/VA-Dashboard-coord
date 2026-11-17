---
name: canada-us-banks-only
description: FEEDBACK 2026-11-12: bank statement reading work is scoped to Canadian and US banks for now; non-North-American samples (ANZ, ABSA, Axis, Banco do Brasil) are out of scope
metadata:
  type: feedback
---

Amin (2026-11-12, during the 23-sample statement test): "before we continue, for now do the work related to the banks of Canada and the USA."

**Why:** the product's clients bank in Canada (and some in the USA); the sample set had 7 countries and the Brazilian, South African, Indian and Australian layouts were pulling checkpoints toward formats no client uses.

**How to apply:** when reading the imports table or choosing the next statement checkpoint, rank only Canadian/US banks (TD, RBC, Scotiabank, BMO, CIBC, Tangerine, Simplii, EQ, Laurentian, Desjardins, Coast Capital, ATB, Bank of America, Ally, Associated); leave ANZ/ABSA/Axis/Banco do Brasil gaps unworked unless Amin asks. Related: [[bank-reconciliation-workspace]].
