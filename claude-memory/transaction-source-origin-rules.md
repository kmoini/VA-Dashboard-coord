---
name: transaction-source-origin-rules
description: How the transaction Source badge should label origin — mobile vs client-workspace vs accountant-dashboard (spec to build later)
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

Amin's intended Source-badge taxonomy for transactions (stated 2026-06-16, asked
to remember — NOT yet implemented). The Source badge in the detail panel
([[checkpoint-rule]] checkpoint-039, `Transactions/Index.jsx` `SOURCE_META`)
currently keys only off the `source` enum (ai|client|accountant) and does NOT yet
follow these rules.

**Desired mapping by ORIGIN:**
1. **From the mobile app** → 📱 (phone icon), labelled **Client / AI** (mobile
   entries are client-captured and/or AI-processed).
2. **From the client workspace** (web client portal) → 👤 **Client**.
3. **From the accountant dashboard** → 👤 **Accountant**.

Key point: the icon distinguishes **mobile (📱) vs web (👤)**; the label says who
(Client/AI vs Client vs Accountant). The current single `source` enum can't tell
mobile-client from workspace-client — both are `source='client'` today.

**Implementation hook (for later):** mobile-originated rows are identifiable by
`transactions.mobile_id IS NOT NULL` (set by `MobileTransactionProjector`, see
[[checkpoint-rule]] checkpoint-021). So origin resolves as:
- `mobile_id` set → mobile → 📱 (Client/AI; use `source` to pick Client vs AI)
- `source='client'` + no `mobile_id` → client workspace → 👤 Client
- `source='accountant'` → 👤 Accountant
- `source='ai'` → AI (mobile AI layer) → likely 📱

Backend needs to expose `mobile_id` (or a derived `origin`) in the
`TransactionsController::index` mapping for the frontend badge to apply this.
Related: [[client-workspace-architecture]].
