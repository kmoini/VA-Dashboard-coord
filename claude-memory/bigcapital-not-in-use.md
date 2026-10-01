---
name: bigcapital-not-in-use
description: "HARD RULE (Amin, repeated, 2026-09-30): Bigcapital / Books is NOT in use and NOT part of the product today; never include it in pricing, plans, feature lists or proposals."
metadata:
  node_type: memory
  type: feedback
  originSessionId: 668f5f60-13cc-428f-8e31-aa15415e6a13
  modified: 2026-09-30T15:53:29.699Z
---

Amin has said several times that Bigcapital (the "Books" module) is not currently in use. It must not appear in pricing tiers, add-ons, cost models, feature lists, reference-firm examples, bank-reconciliation or reporting plans, or any customer-facing proposal. The ledger of record for clients is QuickBooks Online; our own transactions table feeds our reports.

**Why:** old memories ([[bigcapital-deployment]], [[books-phase3-production-deploy]], [[bank-reconciliation-feature]], [[books-multi-company-plan]], [[bigcapital-tenant-storage-ceiling]]) describe Books as live, so Claude keeps re-including it. Those memories are history, not current product scope. On 2026-09-30 the pricing page shipped with Books entities, Books allowances and a Books add-on and had to be stripped.

**How to apply:** before writing any product, pricing or roadmap material, drop every Books/Bigcapital reference unless Amin explicitly brings it back. If a plan needs a ledger, it is QuickBooks (or our own DB), not Bigcapital. Related: [[qbo-api-read-quota]].
