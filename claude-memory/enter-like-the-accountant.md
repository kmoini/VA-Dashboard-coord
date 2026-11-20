---
name: enter-like-the-accountant
description: "FEEDBACK 2026-11-19 (Amin): every field of a row must come from how the accountant treated the vendor before (QBO, Accounting History, approved rows), in every upload path. cp-539 built the tax figure; cycle and bill date still open."
metadata:
  node_type: memory
  type: feedback
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-19T20:06:59.544Z
---

Amin, 2026-11-19 (Axle Corp., Desktop vs QBO): reading the books must not stop at HST. For EVERY field the engine looks at how the accountant treated the vendor and does exactly that, "as if the accountant entered it", both on a Record Keeping upload and on "Upload its document" in Bank Reconciliation.

**Why:** Toronto Hydro notice printed no HST; we booked 409.44, the accountant 362.34 + 47.10. Reports of the two books must match.

**How to apply:**
- Put any such rule in `V2DraftPipeline` (the one pipeline both upload paths reach), never in one screen.
- cp-539 (commit 208f1ca4, 2026-11-19): `BooksTaxResolver` works the tax out INSIDE the amount when the document prints none and the vendor's entries carry it (tax pattern first, then history; 3 entries / 80%). Replaces the old "never invent a tax figure" rule only for this case; the amount still never moves. Doc: docs/TAX-FROM-BOOKS-2026-11-19.md. See [[sales-tax-hst-gst]], [[historical-context-roadmap]].
- cp-540 (5fd6761b, LIVE on prod 2026-11-19, prod test by Amin pending): the accountant names utilities with account and unit ("Toronto Hydro 8877050000(UNIT300)") while the bill prints the legal name, so `VendorMatch::similar` never found the books (account, bank AND tax). `HistoricalContextService::matchingNames` now compares the name without number tokens; the numbers printed on the document pick the meter. Check name matching FIRST when "history exists but nothing was decided".
- Still NOT from the books (needs the accounting team): bill vs direct purchase (suggestion only), the date of a bill. My interpretation: Amin wants these too once the team answers.
- It only works for a company whose books we hold. Axle's real books are in Desktop: check whether its history is imported before promising results.
